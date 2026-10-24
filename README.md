# 👋 Hi, I'm Kurt

Junior data engineer building pipelines on my own infrastructure. I like turning messy public data into clean, tested, trustworthy analytics, with a particular interest in aviation and in construction and insurance risk.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)]([YOUR_LINKEDIN_URL](https://www.linkedin.com/in/kurtmccleansr/))

## 🚀 Projects

**[Flight Operations Pipeline](https://github.com/itxos/flight-ops-pipeline)**
An ELT pipeline that ingests live flight data for ORD, MSP, and ATL from the AeroDataBox API, models it with dbt, and serves delay and cancellation analytics in Metabase. While validating the results, I found that the API's timestamps mixed runway and gate times, which skewed departure delays, and redefined the headline metric around arrivals.

**[Texas Construction Safety Pipeline](https://github.com/itxos/construction-risk-pipeline)**
A scheduled pipeline that loads federal OSHA inspection and citation records for Texas construction employers from the Department of Labor API. It handles an undocumented rate limit with a resumable loader, accounts for citations that post months after an inspection, and enforces privacy rules in the database so the dashboard never exposes company names.

Both run on a self-hosted Proxmox VM with Docker Compose, Airflow, PostgreSQL, dbt, and Metabase.

## 🛠️ Tools I work with

![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=flat&logo=postgresql&logoColor=white)
![Airflow](https://img.shields.io/badge/Airflow-017CEE?style=flat&logo=apacheairflow&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-FF694B?style=flat&logo=dbt&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Postgres](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)
![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=flat&logo=proxmox&logoColor=white)

## 🔭 Currently

- Self-hosting everything on a Proxmox server

## 📫 Get in touch



Best way to reach me is [LinkedIn](https://www.linkedin.com/in/kurtmccleansr/?isSelfProfile=true).
<a href="https://linkedin.com"><img src="https://img.shields.io/badge/-LinkedIn-0072b1?&style=for-the-badge&logo=linkedin&logoColor=white" /></a>

