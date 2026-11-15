# 🏥 Healthcare CRM – Salesforce Service Cloud

A complete **patient support system** for a multi-branch hospital chain, built on **Salesforce Service Cloud**.

Patients contact the hospital by **email, web form, live chat or phone**. Every request becomes a **Case** that is
automatically classified, routed to the right department, worked by an agent in a console, tracked against an
**SLA**, escalated if it is late, and reported on in dashboards. Patients can also help themselves through a
**self-service portal** with knowledge articles and a **chatbot** that hands over to a live agent.

> 📚 Built as a hands-on learning project covering **40 business requirements across 10 functional areas**.
> All sample data in this repository is fictional.

---

## 📑 Table of Contents

1. [Business Problem](#-business-problem)
2. [Solution Overview](#-solution-overview)
3. [Features by Module](#-features-by-module)
4. [Case Lifecycle](#-case-lifecycle)
5. [Data Model](#-data-model)
6. [Case Types, Departments and Routing](#-case-types-departments-and-routing)
7. [SLA and Escalation](#-sla-and-escalation)
8. [Security Model](#-security-model)
9. [Automation (Flows)](#-automation-flows)
10. [Apex Code](#-apex-code)
11. [Reports and Dashboards](#-reports-and-dashboards)
12. [Project Structure](#-project-structure)
13. [How to Deploy](#-how-to-deploy)
14. [Optional Demo Data](#-optional-demo-data)
15. [Tech Stack](#-tech-stack)
16. [What I Learned](#-what-i-learned)
17. [Future Enhancements](#-future-enhancements)

---

## 🎯 Business Problem

The hospital chain handled patient requests through scattered inboxes and phone lines:

- Requests about appointments, bills, insurance claims, feedback and technical issues all arrived in one place.
- Nobody knew **who owned** a request or **how long** it had been waiting.
- Urgent medical concerns were treated the same as routine questions.
- Patients repeatedly called for simple answers (visiting hours, how to pay a bill, claim documents).
- Management had **no visibility** into volumes, response times or patient satisfaction.
- Patient data is sensitive and needed **strict, role-based access** (HIPAA-style privacy).

## 💡 Solution Overview

| Need | Salesforce solution |
|---|---|
| One record per request | **Cases** with 5 record types |
| Know who the patient is | Custom **Patient** object linked to Contact, with appointments and bills |
| Requests from many channels | **Email-to-Case**, **Web-to-Case**, **Messaging (web chat)**, phone |
| Right team, right agent | **Assignment rules → queues → Omni-Channel** with priority and capacity |
| Response-time promises | **Entitlements & milestones** (SLA) + **escalation rules** |
| Fewer repeat questions | **Lightning Knowledge**, **Experience Cloud portal**, **Einstein Bot** |
| Less manual work | **Record-triggered & scheduled Flows**, **Apex** trigger and batch jobs |
| Visibility | **Reports & dashboard** for volume, SLA compliance, satisfaction |
| Privacy | **Private sharing**, role hierarchy, profiles, permission sets, field-level security |

---

## ✨ Features by Module

### 1. Patient Data Management
- `Patient__c` custom object: email, phone, date of birth, gender, insurance provider, preferred language.
- Each patient is linked to a **Contact** so they can email in, use the portal and be emailed back.
- `Appointment__c` and `Billing__c` are **master-detail** children of Patient (deleting a patient removes them).
- **Duplicate and matching rules** stop the same patient being created twice (email / phone match).
- Page layouts and Lightning record pages show related appointments, bills and cases on the patient.

### 2. Case Management
- Custom Case fields: **Patient**, **Urgency**, **Department**, **Appointment**, **Billing**, **SLA Violated**,
  **SLA Breach Count** (formula), **Satisfaction Score**.
- **5 record types**, each with its own page layout, sharing one **Support Process** (`Patient Support Process`)
  with the statuses *New → Working → Waiting on Patient → Resolved → Closed*.
- Validation rules keep data clean (e.g. urgency required).

### 3. Multi-Channel Intake
- **Email-to-Case** – four routing addresses (appointments, billing, insurance, feedback); the origin tells the
  system what the email is about.
- **Auto-response rule** – patients get an instant acknowledgement with their case number.
- **Web-to-Case** – a public contact form (hosted on GitHub Pages) creates cases directly.
- **Messaging for In-App and Web** – live chat widget embedded on the website.
- **Phone** – agents log calls as cases from the console.

### 4. Routing and Agent Workspace
- **Case assignment rule** sends each case to one of **5 department queues**.
- **Omni-Channel** pushes work to available agents, by **priority** (Critical first) and **capacity** (5 items per agent).
- **Presence statuses** (Available / Busy / Break) control when agents receive work.
- **Patient Service Console** – a Lightning console app with tabs, split view and utility bar.

### 5. Knowledge Base
- **Lightning Knowledge** with a *Patient Topics* data category group
  (Appointments, Billing, Insurance, General).
- Articles are suggested to agents on cases and shown to patients in the portal.
- Separate author access via permission set; publishing controlled by the admin.

### 6. Self-Service Portal and Chatbot
- **Experience Cloud** customer portal (**Medi_Flow**) where patients log in to:
  - view and create their own cases (**Sharing Sets** limit them to their own records),
  - search knowledge articles.
- **Einstein Bot** answers common questions and offers **"Talk to an agent"**, which transfers the
  conversation to a live agent queue through Omni-Channel.

### 7. SLA Management
- **Entitlement Management** with a *Standard Patient Support* entitlement.
- **Entitlement process** with urgency-based **Resolution Time** milestones.
- **Escalation rule** for high-priority cases left unresolved.
- Milestones complete automatically when a case is closed.

### 8. Automation
- Flows classify incoming cases, complete milestones, notify patients, auto-close resolved cases and send weekly
  reminders (details below).

### 9. Apex Development
- Trigger with handler pattern, scheduled summary email and a monthly batch report (details below).
- Full unit test coverage including a 100-record bulk test.

### 10. Reporting and Security
- Reports and a *Support Overview* dashboard.
- Role hierarchy, profiles, private org-wide defaults, sharing rules and field-level security.

---

## 🔄 Case Lifecycle

```
 Patient
   │  email • web form • chat • phone
   ▼
 ┌──────────────────────────────┐
 │ Case created                  │
 └──────────────┬───────────────┘
                ▼
   Flow: Classify Incoming  ─ sets Record Type, Department, Urgency, links Patient
                ▼
   Apex trigger            ─ attaches Entitlement (SLA), blocks duplicate open cases
                ▼
   Assignment rule         ─ puts case in the department queue
                ▼
   Omni-Channel            ─ routes to an available agent by priority
                ▼
   Agent works the case in the Patient Service Console (uses Knowledge articles)
                │
                ├─ status changes → Flow emails the patient
                ├─ SLA milestone running → escalation if breached
                ▼
   Resolved ─(scheduled path)→ Closed automatically, milestone completed
                ▼
   Weekly summary email • Monthly SLA report • Dashboard
```

---

## 🗂 Data Model

```
Account (Hospital Patients)
   │
   └── Contact ───────────── Patient__c
                                │
                                ├── Appointment__c   (master-detail)
                                ├── Billing__c       (master-detail)
                                └── Case             (lookup)
                                      ├── Appointment__c (lookup)
                                      ├── Billing__c     (lookup)
                                      └── Entitlement ── Milestones
```

| Object | Key fields |
|---|---|
| **Patient__c** | Name, Email, Phone, Date of Birth, Gender, Insurance Provider, Preferred Language, Contact |
| **Appointment__c** | Patient, Date/Time, Department, Doctor Name, Status (Scheduled / Completed / No-Show / Cancelled) |
| **Billing__c** | Patient, Amount, Invoice Date, Payment Status (Paid / Unpaid / Partially Paid / Disputed), Payment Reference |
| **Case** (custom fields) | Patient, Urgency (Low / Medium / High / Critical), Department, Appointment, Billing, SLA Violated, SLA Breach Count, Satisfaction Score |

---

## 🧭 Case Types, Departments and Routing

| Record Type | Department / Queue | Typical origin | Example |
|---|---|---|---|
| Appointment | Scheduling | Email-Appointments, Phone | Reschedule a follow-up |
| Billing | Finance | Email-Billings, Web | Question about a charge |
| Insurance | Claims | Email-Insurance | Cashless claim status |
| Feedback | Medical Review | Email-Feedback, Web | Complaint or compliment |
| Technical | IT Support | Web, Chat | Can't log in to the portal |

**Omni-Channel priority:** Critical → High → Medium → Low, so urgent cases reach agents first.

**Why both Record Type and Department?**
Record type controls the *form* (layout, picklist values); Department drives *routing and reporting*.
Keeping them separate lets one case type be reassigned to another team without changing its form.

---

## ⏱ SLA and Escalation

| Urgency | Resolution target |
|---|---|
| Critical | 4 hours |
| High | 12 hours |
| Medium | 24 hours |
| Low | 48 hours |

- The **Apex trigger** attaches the entitlement to every new case, which starts the milestone clock.
- When the milestone is missed, the case is flagged as **SLA Violated**.
- The **escalation rule** reassigns/notifies supervisors for high-priority cases still open after 12 hours.
- A **flow** completes the milestone when the case is closed.

---

## 🔐 Security Model

**Role hierarchy**
```
Admin
 ├── Supervisor ── Agent
 └── Medical Director ── Doctor
```

| Layer | Configuration |
|---|---|
| Org-wide defaults | **Private** for Patient and Case – users see only what they own or are granted |
| Roles | Managers see their team's records through the hierarchy |
| Profiles | Support, Support Supervisor, Finance, Insurance, Medical, Patient Portal |
| Permission sets | Extra access (e.g. Knowledge authoring) without new profiles |
| Public groups + sharing rules | Finance Team sees billing cases, Claims Team sees insurance cases |
| Field-level security | Sensitive fields hidden from roles that don't need them |
| Portal | Sharing Sets – patients only see cases linked to their own contact |

---

## ⚙ Automation (Flows)

| Flow | Type | What it does |
|---|---|---|
| Case – Classify Incoming | Record-triggered, before save | Sets record type, department and urgency from the origin; links the patient by email |
| Complete Milestones | Record-triggered, after save | Marks SLA milestones complete when a case closes |
| Auto Close Resolved | Record-triggered with scheduled path | Closes cases that stay *Resolved* for a set time |
| Notify Patient on Status Change | Record-triggered, after save | Emails the patient when status changes |
| Weekly Insurance Reminders | Schedule-triggered | Reminds about open insurance cases each week |
| Chat Entry – To Bot | Omni-Channel flow | Sends new chat conversations to the bot |
| Chat Transfer – To Queue | Omni-Channel flow | Routes "talk to an agent" requests to a live agent queue |

Other declarative automation: **assignment rule**, **auto-response rule**, **escalation rule**, **entitlement process**.

---

## 💻 Apex Code

| Class | Type | Purpose |
|---|---|---|
| `CaseTrigger` | Trigger (before insert) | Thin trigger – delegates to the handler |
| `CaseTriggerHandler` | Handler class | Assigns the *Standard Patient Support* entitlement and **blocks a duplicate open case** of the same type for the same patient |
| `WeeklyCaseSummary` | Schedulable | Emails supervisors a weekly case summary (Mondays 8 AM) |
| `MonthlySlaComplianceBatch` | Batchable + Stateful | Calculates last month's SLA compliance by department and emails admins |
| `MonthlySlaComplianceScheduler` | Schedulable | Starts the batch on the 1st of every month |
| `CaseTriggerHandlerTest`, `WeeklyCaseSummaryTest`, `MonthlySlaComplianceBatchTest` | Tests | Positive, negative and **bulk (100 records)** tests |

**Practices used**
- **Trigger handler pattern** – one trigger per object, logic in a class.
- **Bulkification** – no SOQL or DML inside loops; one query for all records in the transaction.
- **`addError()`** to show a friendly message instead of failing the whole save.
- **`Database.Stateful`** to keep totals across batch chunks.
- **`Test.startTest()/stopTest()`**, `Test.setCreatedDate()` and `@TestVisible` for reliable tests.

**Schedules**
```apex
System.schedule('Weekly Case Summary', '0 0 8 ? * MON', new WeeklyCaseSummary());
System.schedule('Monthly SLA Compliance', '0 0 7 1 * ?', new MonthlySlaComplianceScheduler());
```

---

## 📊 Reports and Dashboards

| Report | Shows |
|---|---|
| Open Cases | All unresolved cases by department and urgency |
| Open vs Closed Cases | Workload balance |
| Case Volume by Type | Which requests are most common |
| Monthly Case Trend | Volume over time |
| SLA Compliance by Type | `1 − (SLA breaches ÷ total cases)` per record type |
| SLA Breaches by Type and Agent | Where and with whom SLAs are missed |
| Agent Productivity | Cases closed per agent per day |
| Patient Satisfaction | Average satisfaction score |

All of these feed the **Support Overview** dashboard.

---

## 📁 Project Structure

```
.
├── force-app/main/default/
│   ├── classes/              Apex classes and tests
│   ├── triggers/             CaseTrigger
│   ├── objects/              Patient__c, Appointment__c, Billing__c, Case, Account, Contact
│   │                         (fields, record types, validation rules, list views)
│   ├── layouts/              Page layouts
│   ├── flexipages/           Lightning record pages
│   ├── flows/                All flows
│   ├── profiles/  roles/  permissionsets/  groups/  sharingRules/
│   ├── queues/  assignmentRules/  autoResponseRules/  escalationRules/
│   ├── entitlementProcesses/  milestoneTypes/
│   ├── serviceChannels/  queueRoutingConfigs/  presenceUserConfigs/
│   ├── applications/         Patient Service Console
│   ├── datacategorygroups/   Patient Topics
│   ├── bots/  networks/  experiences/  EmbeddedServiceConfig/
│   ├── email/                Email templates
│   └── reports/  dashboards/
├── manifest/package.xml      List of everything retrieved from the org
├── scripts/apex/
│   ├── seed-showcase-data.apex      Optional demo data
│   └── cleanup-showcase-data.apex   Removes the demo data
└── README.md
```

---

## 🚀 How to Deploy

**Prerequisites:** a Salesforce Developer Edition org, [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli),
VS Code with the Salesforce Extension Pack.

**1. Enable these features in the target org first** (Setup):
- Entitlement Management
- Lightning Knowledge
- Omni-Channel
- Digital Experiences (Experience Cloud)
- Messaging for In-App and Web
- Einstein Bots

**2. Clone and deploy**
```bash
git clone https://github.com/<your-username>/healthcare-crm-service-cloud.git
cd healthcare-crm-service-cloud
sf org login web --alias healthcare
sf project deploy start --manifest manifest/package.xml --target-org healthcare
```

**3. Finish the manual setup** (these settings can't be stored as metadata):
- Email-to-Case routing addresses and their verification
- Web-to-Case settings and HTML form
- Messaging channel and embedded-service code snippet on the website
- Activate the portal and add member profiles
- Assign users to roles, profiles, permission sets and queues
- Schedule the Apex jobs (see [Apex Code](#-apex-code))

**4. Run the tests**
```bash
sf apex run test --test-level RunLocalTests --target-org healthcare --result-format human
```

---

## 🧪 Optional Demo Data

The repository contains **no records** – only configuration and code.
To fill an org with realistic sample data for a demo:

```bash
sf apex run --file scripts/apex/seed-showcase-data.apex --target-org healthcare
```
This creates **12 patients, 14 appointments, 10 bills and 24 cases** across all types, statuses, channels and
urgency levels. All emails use `@demo.example.com`.

To remove it again:
```bash
sf apex run --file scripts/apex/cleanup-showcase-data.apex --target-org healthcare
```

---

## 🛠 Tech Stack

| Category | Tools |
|---|---|
| Platform | Salesforce Service Cloud, Experience Cloud |
| Channels | Email-to-Case, Web-to-Case, Messaging for In-App and Web |
| Service tools | Omni-Channel, Lightning Console, Lightning Knowledge, Entitlement Management, Einstein Bots |
| Automation | Flow Builder, Assignment / Auto-Response / Escalation Rules |
| Code | Apex, SOQL, Apex Testing |
| Analytics | Reports and Dashboards |
| Dev tools | Salesforce CLI, VS Code, Git, GitHub |

---

## 📖 What I Learned

- Designing a data model with the right mix of **lookup and master-detail** relationships.
- The difference between **roles** (what records you see) and **profiles** (what you can do).
- Combining **declarative tools first** and **Apex only where needed**.
- How Email-to-Case, assignment rules, queues and Omni-Channel fit together into one routing pipeline.
- Building SLAs with **entitlements, milestones and escalation rules**.
- Writing **bulk-safe Apex**, batch and scheduled jobs, and meaningful unit tests.
- Debugging with debug logs, flow debug mode and Apex test history.
- Moving configuration between an org and source control with the **Salesforce CLI**.

## 🔭 Future Enhancements

- Lightning Web Components for a patient 360° view
- SMS / WhatsApp channel through Messaging
- Surveys after case closure to collect satisfaction automatically
- Einstein Case Classification to predict case type
- CI/CD pipeline with GitHub Actions to validate deployments

---

## 👤 Author

**Vaishnavi Kubade** – Salesforce Developer / Admin
[LinkedIn]([https://www.linkedin.com/in/your-profile](https://www.linkedin.com/in/vaishnavi-kubade-9b7aa11bb/)) • [GitHub]([https://github.com/your-username](https://github.com/vaishnavikubade09))
