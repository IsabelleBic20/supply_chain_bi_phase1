# Supply Chain BI & Data Stewardship Project

Um projeto prático de engenharia analítica e governança de dados focado no ecossistema de **Supply Chain**, simulando os desafios reais enfrentados por um **Data Steward / BI Data Engineer**.

O projeto cobre todo o ciclo de vida dos dados: desde a ingestão e investigação forense de dados brutos (*Data Profiling & Quality Assessment*), análise de causa raiz e governança, até a transformação na camada *Staging*, modelagem dimensional (Kimball) e consumo analítico no Tableau.

---

## 1. Objetivo do Projeto

Transformar dados operacionais brutos de Supply Chain com inconsistências reais em uma base analítica governada, confiável e pronta para tomada de decisão em BI.

```text
  ┌──────────────┐      ┌─────────────────────────┐      ┌───────────────────────┐
  │   RAW DATA   │ ───► │  PROFILING & DQ CHECKS  │ ───► │  ROOT CAUSE ANALYSIS  │
  └──────────────┘      └─────────────────────────┘      └───────────────────────┘
                                                                     │
                                                                     ▼
  ┌──────────────┐      ┌─────────────────────────┐      ┌───────────────────────┐
  │ TABLEAU / BI │ ◄─── │   DIMENSIONAL MODEL     │ ◄─── │     STAGING LAYER     │
  └──────────────┘      │    (Star Schema)        │      │ (Governed & Flagged)  │
                        └─────────────────────────┘      └───────────────────────┘
```

---

## 2. Estrutura do Repositório

```text
supply_chain_bi_phase1/
├── data/
│   └── raw/                     # Dados brutos operacionais (imutáveis)
│       ├── carriers.csv         # Transportadoras
│       ├── customers.csv        # Cadastro de clientes
│       ├── deliveries.csv       # Histórico de entregas e fretes
│       ├── orders.csv           # Pedidos de venda
│       ├── products.csv         # Catálogo de produtos
│       ├── suppliers.csv        # Fornecedores
│       └── warehouses.csv       # Centros de distribuição / Armazéns
├── docs/
│   └── data_quality_matrix.md   # Matriz oficial de regras e governança de dados
├── sql/
│   ├── profiling.sql            # Script SQL para profiling e validação de regras
│   └── root_cause_analysis.sql  # Script de investigação de anomalias
├── data_inventory.csv           # Inventário de metadados das tabelas
└── README.md                    # Documentação principal do projeto
```

---

## 3. Inventário de Dados Brutos (Raw Layer)

| Tabela | Volume de Registros | Chave Primária (PK) | Granularidade / Descrição |
| :--- | :---: | :---: | :--- |
| **`orders`** | 100.080 | `order_id` | 1 linha = 1 item/pedido transacional |
| **`deliveries`** | 100.050 | `delivery_id` | 1 linha = 1 remessa/despacho logístico |
| **`customers`** | 5.000 | `customer_id` | 1 linha = 1 cliente cadastrado |
| **`products`** | 1.000 | `product_id` | 1 linha = 1 produto no catálogo |
| **`warehouses`** | 12 | `warehouse_id` | 1 linha = 1 armazém / centro de distribuição |
| **`suppliers`** | 80 | `supplier_id` | 1 linha = 1 fornecedor homologado |
| **`carriers`** | 15 | `carrier_id` | 1 linha = 1 transportadora parceira |

---

## 4. Diagnóstico de Qualidade dos Dados (Data Profiling)

Abaixo estão os resultados consolidados das validações executadas via DuckDB sobre a camada bruta:

| ID | Dimensão de DQ | Regra Validada | Violações | Status | Severidade | Ação Proposta |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **DQ-001** | Uniqueness | `orders.order_id` único | 80 | **FAIL** | Crítica | Deduplicação na Staging via janela |
| **DQ-002** | Uniqueness | `deliveries.delivery_id` único | 50 | **FAIL** | Crítica | Deduplicação na Staging |
| **DQ-003** | Completeness | `orders.customer_id` não nulo | 120 | **FAIL** | Alta | Mapear para *Unknown Customer* (-1) |
| **DQ-004** | Referential Integrity | `customer_id` existente em `customers` | 50 | **FAIL** | Alta | Mapear para *Generic Customer* (-2) |
| **DQ-005** | Validity | `quantity > 0` | 60 | **FAIL** | Alta | Sinalizar via flag (`dq_flag_negative_qty`) |
| **DQ-006** | Consistency | `order_value = quantity * unit_price` | 60 | **FAIL** | Alta | Investigar correlação com DQ-005 |
| **DQ-007** | Standardization | Vocabulário controlado de `status` | 100 | **FAIL** | Média | Normalização de strings na Staging |
| **DQ-008** | Completeness | `transport_cost` não nulo | 100 | **FAIL** | Média | Sinalizar valor ausente / imputação |
| **DQ-009** | Validity | `actual_delivery_date >= order_date` | 75 | **FAIL** | Crítica | Flag de inconsistência temporal |
| **DQ-010** | Cardinality | Múltiplas entregas por pedido | 50 | **FAIL** | Média | Validado como duplicação técnica |

---

## 5. Análise de Causa Raiz & Visão de Data Steward

Como Data Stewards, os problemas não são tratados com comandos destrutivos (`DELETE`), mas sim compreendidos e governados:

### A. Quantidades Negativas & Inconsistência de Faturamento (DQ-005 / DQ-006)
* **Evidência:** 60 pedidos possuem `quantity = -21`, `unit_price = 34.41` e `order_value = 722.61`.
* **Descoberta:** `ABS(quantity) * unit_price` é exatamente igual a `order_value`.
* **Causa Raiz:** Erro de sinal/formatação na ingestão ou modelagem imprópria de devoluções sem flag de estorno.
* **Decisão:** Não alterar o dado original de forma cega; criar flag de auditoria e tratar com `ABS(quantity)` após validação formal com o time de negócio.

### B. Clientes Nulos vs. Clientes Órfãos (DQ-003 / DQ-004)
* **Evidência:** 120 pedidos com `customer_id IS NULL` e 50 pedidos com IDs não cadastrados (ex.: `C99999`).
* **Distinção Essencial:**
  * *Completude (Missing Value):* Compras anônimas / *Guest Checkout*.
  * *Integridade Referencial (Invalid Reference):* Código genérico de PDV/Balcão ou exclusão de cadastro (LGPD) sem integridade relacional.
* **Decisão Dimensional:** Manter os pedidos para preservar o faturamento real da empresa, aplicando a estratégia Kimball de membros especiais (`-1: Não Informado`, `-2: Cliente Genérico`).

### C. Múltiplas Entregas por Pedido (DQ-002 / DQ-010)
* **Evidência:** 50 pedidos possuem 2 linhas de entrega associadas.
* **Investigação:** Ao avaliar a cardinalidade, descobriu-se que `distinct_delivery_ids = 1`.
* **Conclusão:** Não se trata de *Split Shipment* (despacho fracionado legítimo), mas sim de **duplicação técnica de registros de entrega** por *retry* na ingestão.

### D. Padronização de Status (DQ-007)
* **Evidência:** Variações como `Delivered` vs `delivered`, `In Transit` vs `in_transit`, `Cancelled` vs `Canceled`.
* **Impacto no BI:** Evita fragmentação de métricas e filtros inconsistentes no Tableau.
* **Decisão:** Normalização categórica padronizada na camada de transformação.

---

## 6. Princípios de Governança de Dados Adotados

1. **Imutabilidade da Camada Raw:** Dados brutos jamais são sobrescritos ou apagados.
2. **Transformação Declarativa e Rastreável:** Correções e enriquecimentos ocorrem estritamente na camada *Staging*.
3. **Preservação do Faturamento:** Registros com falha de chave estrangeira não são deletados, evitando distorções contábeis no BI.
4. **Metadados de Qualidade (DQ Flags):** Registros duvidosos são marcados com flags booleanas para fácil auditoria e filtragem analítica.

---

## 7. Roadmap do Projeto

- [x] **Fase 1: Configuração do Ambiente & Ingestão Raw**
- [x] **Fase 2: Data Profiling com SQL (DuckDB)**
- [x] **Fase 3: Análise de Causa Raiz (RCA)**
- [x] **Fase 4: Matriz de Qualidade & Regras de Governança**
- [ ] **Fase 5: Construção da Camada Staging (`stg_orders`, `stg_deliveries`, etc.)**
- [ ] **Fase 6: Modelagem Dimensional (Star Schema / Kimball)**
  - Tabela Fato: `fct_orders`, `fct_deliveries`
  - Dimensões: `dim_customers`, `dim_products`, `dim_carriers`, `dim_warehouses`, `dim_date`
- [ ] **Fase 7: Engenharia de Métricas (OTIF, Lead Time, OTD, Frete Médio)**
- [ ] **Fase 8: Desenvolvimento de Dashboards Executivos no Tableau**

---

## 8. Como Executar o Profiling

Para reproduzir os testes de qualidade dos dados localmente:

```bash
# Executar a suíte de profiling com DuckDB
duckdb < sql/profiling.sql

# Executar a investigação de causa raiz
duckdb < sql/root_cause_analysis.sql
```
