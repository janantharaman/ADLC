#!/usr/bin/env python3
"""Generate PDF from the ADLC for Salesforce design document."""

import textwrap
from fpdf import FPDF


class DesignPDF(FPDF):
    def __init__(self):
        super().__init__()
        self.set_auto_page_break(auto=True, margin=20)
        self.set_margins(20, 20, 20)

    def header(self):
        if self.page_no() > 1:
            self.set_font("Helvetica", "I", 8)
            self.set_text_color(130, 130, 130)
            self.cell(0, 8, "ADLC for Salesforce", align="R")
            self.ln(4)
            self.set_draw_color(200, 200, 200)
            self.line(20, self.get_y(), self.w - 20, self.get_y())
            self.ln(6)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(130, 130, 130)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="C")

    def h1(self, text):
        self.ln(4)
        self.set_font("Helvetica", "B", 18)
        self.set_text_color(20, 60, 120)
        self.multi_cell(0, 10, text)
        self.set_draw_color(20, 60, 120)
        self.line(20, self.get_y(), self.w - 20, self.get_y())
        self.ln(4)

    def h2(self, text):
        self.ln(3)
        self.set_font("Helvetica", "B", 14)
        self.set_text_color(40, 80, 140)
        self.multi_cell(0, 8, text)
        self.ln(2)

    def h3(self, text):
        self.ln(2)
        self.set_font("Helvetica", "B", 11)
        self.set_text_color(60, 60, 60)
        self.multi_cell(0, 6, text)
        self.ln(1)

    def p(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_text_color(40, 40, 40)
        self.multi_cell(0, 5.5, text)
        self.ln(2)

    def bold_label(self, label, value):
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(40, 40, 40)
        w = self.get_string_width(label) + 2
        self.cell(w, 5.5, label)
        self.set_font("Helvetica", "", 10)
        self.multi_cell(0, 5.5, value)
        self.ln(1)

    def bullet(self, text, indent=0):
        x = 25 + indent
        self.set_x(x)
        self.set_font("Helvetica", "", 10)
        self.set_text_color(40, 40, 40)
        self.cell(5, 5.5, "-")
        self.multi_cell(0, 5.5, text)
        self.ln(0.5)

    def num(self, n, text):
        self.set_x(25)
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(20, 60, 120)
        self.cell(8, 5.5, f"{n}.")
        self.set_font("Helvetica", "", 10)
        self.set_text_color(40, 40, 40)
        self.multi_cell(0, 5.5, text)
        self.ln(1)

    def code(self, text):
        self.set_fill_color(245, 245, 245)
        self.set_draw_color(200, 200, 200)
        self.set_font("Courier", "", 8)
        self.set_text_color(50, 50, 50)
        lines = text.strip().split("\n")
        x, max_w = 25, self.w - 45
        block_h = len(lines) * 4 + 4
        if self.get_y() + block_h > self.h - 25:
            self.add_page()
        y0 = self.get_y()
        self.rect(x - 2, y0 - 1, max_w + 4, block_h, style="DF")
        self.set_xy(x, y0 + 1)
        for line in lines:
            self.set_x(x)
            self.cell(max_w, 4, line[:100])
            self.ln(4)
        self.ln(3)

    def table(self, headers, rows, col_widths=None):
        usable = self.w - 40
        n = len(headers)
        if col_widths is None:
            col_widths = [usable / n] * n
        else:
            total = sum(col_widths)
            col_widths = [w / total * usable for w in col_widths]

        self.set_font("Helvetica", "B", 8)
        self.set_fill_color(20, 60, 120)
        self.set_text_color(255, 255, 255)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 6, h, border=1, fill=True, align="C")
        self.ln()
        self.set_text_color(40, 40, 40)
        fill = False
        for row in rows:
            if fill:
                self.set_fill_color(240, 245, 250)
            else:
                self.set_fill_color(255, 255, 255)
            cell_texts = []
            max_lines = 1
            for i, cell in enumerate(row):
                chars = max(int(col_widths[i] / 1.8), 12)
                wrapped = textwrap.wrap(cell, width=chars) or [""]
                cell_texts.append(wrapped)
                max_lines = max(max_lines, len(wrapped))
            row_h = max_lines * 4.2
            if self.get_y() + row_h > self.h - 25:
                self.add_page()
            y0 = self.get_y()
            x_pos = 20
            self.set_font("Helvetica", "", 8)
            for i, texts in enumerate(cell_texts):
                self.set_xy(x_pos, y0)
                self.rect(x_pos, y0, col_widths[i], row_h, style="DF")
                for j, line in enumerate(texts):
                    self.set_xy(x_pos + 1, y0 + j * 4.2 + 0.5)
                    self.cell(col_widths[i] - 2, 4.2, line[:65])
                x_pos += col_widths[i]
            self.set_y(y0 + row_h)
            fill = not fill
        self.ln(4)

    def page_break(self):
        self.add_page()


def build():
    pdf = DesignPDF()
    pdf.alias_nb_pages()
    pdf.add_page()

    # ===== TITLE PAGE =====
    pdf.ln(40)
    pdf.set_font("Helvetica", "B", 30)
    pdf.set_text_color(20, 60, 120)
    pdf.multi_cell(0, 14, "ADLC for Salesforce")
    pdf.ln(6)
    pdf.set_draw_color(20, 60, 120)
    pdf.line(20, pdf.get_y(), pdf.w - 20, pdf.get_y())
    pdf.ln(8)
    pdf.set_font("Helvetica", "", 14)
    pdf.set_text_color(80, 80, 80)
    pdf.multi_cell(0, 7, "Agent Development Life Cycle\nA Phase-Based Agent Architecture\nwith Dynamic Knowledge Retrieval")
    pdf.ln(30)
    pdf.set_font("Helvetica", "", 11)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(0, 7, "LKInsurance Project", align="C")
    pdf.ln(7)
    pdf.cell(0, 7, "April 2026  |  Version 2.0", align="C")
    pdf.page_break()

    # ===== TOC =====
    pdf.h1("Table of Contents")
    toc = [
        "1. Executive Summary",
        "2. Design Principles",
        "3. System Architecture (incl. Model Selection, Extended Thinking)",
        "4. Phase Agents (Discovery, Design, Implementation, Testing, Deployment, Quick Fix)",
        "5. Knowledge Layer (DX MCP, Local RAG, Prompt Caching, Citations)",
        "6. Artifact Handoff System",
        "7. Directory Structure",
        "8. Cursor Hooks Configuration",
        "9. MCP Configuration",
        "10. Extending to New Salesforce Clouds",
        "11. Context Budget Analysis",
        "12. Phase Evaluation Framework (incl. Structured Output Schemas)",
        "13. Implementation Roadmap",
        "14. Retrofitting Existing Projects",
    ]
    for t in toc:
        pdf.bullet(t)
    pdf.page_break()

    # ===== 1. EXECUTIVE SUMMARY =====
    pdf.h1("1. Executive Summary")
    pdf.p(
        "This proposal defines an AI-assisted development system for Salesforce projects "
        "built on two core ideas:"
    )
    pdf.h3("One agent per SDLC phase")
    pdf.p(
        "Instead of loading every possible skill and rule into a single conversation, each phase of "
        "development -- Discovery, Design, Implementation, Testing, Deployment -- is handled by a "
        "dedicated AI agent with a focused context window. A human reviews and approves the output of "
        "each phase before the next begins. A lightweight Quick Fix agent handles trivial tasks that "
        "do not warrant the full pipeline."
    )
    pdf.h3("Dynamic knowledge retrieval")
    pdf.p(
        "Instead of manually curating knowledge bases per Salesforce cloud, the system uses two MCP "
        "servers -- the official Salesforce DX MCP Server for live org data and LWC knowledge, and "
        "a local RAG server backed by automatically downloaded Salesforce documentation for industry "
        "cloud knowledge. Adding support for a new Salesforce cloud takes minutes, not hours."
    )
    pdf.p(
        "The system further optimizes by assigning model tiers per task -- frontier models (Opus, o3) "
        "for architecture and design reasoning, balanced models (Sonnet, GPT-4.1) for code generation, "
        "and fast models (Haiku, Gemini Flash) for test boilerplate and declarative configuration. A "
        "structured evaluation framework with automated checks and scored rubrics governs every phase "
        "gate, ensuring quality is measured consistently rather than left to ad-hoc review."
    )
    pdf.h3("Claude API Platform Features")
    pdf.p(
        "The architecture leverages six Claude-specific API features: Extended Thinking provides "
        "auditable reasoning traces for frontier-tier architecture decisions; Prompt Caching reduces "
        "rule-content token costs by ~60-70%; Message Batches enables parallel test generation at 50% "
        "cost reduction; Citations make every RAG-sourced claim traceable; Structured Outputs produce "
        "machine-readable evaluation artifacts for programmatic gate enforcement; and Cursor Hooks "
        "automate phase transitions, prerequisite validation, and metrics logging."
    )
    pdf.p(
        "Together, these produce a system that is phase-disciplined, context-efficient, "
        "human-governed, cloud-extensible, cost-optimized, and production-focused."
    )

    # ===== 2. DESIGN PRINCIPLES =====
    pdf.h1("2. Design Principles")
    pdf.bold_label("Focused context over universal context. ",
                   "Each agent loads only the rules and knowledge relevant to its phase. This keeps "
                   "the context window lean (30-65KB per agent) and reduces noise, contradictions, "
                   "and hallucination risk.")
    pdf.ln(2)
    pdf.bold_label("Structural human-in-the-loop. ",
                   "Human review is not a rule the AI must remember to follow -- it is a physical "
                   "gate between phases. The Implementation agent cannot run until a human has "
                   "approved the Design artifact.")
    pdf.ln(2)
    pdf.bold_label("Artifacts as contracts. ",
                   "Phases communicate through structured markdown artifacts, not conversation "
                   "history. Each artifact is self-contained.")
    pdf.ln(2)
    pdf.bold_label("Two knowledge sources, clear boundaries. ",
                   "The Salesforce DX MCP Server handles live org operations and built-in LWC/SLDS "
                   "knowledge. A local RAG MCP server handles industry cloud documentation. No overlap.")
    pdf.ln(2)
    pdf.bold_label("Cloud-extensible by configuration. ",
                   "Adding a new Salesforce cloud requires editing one JSON file and running one CLI "
                   "command. No code changes, no account dependencies, no manual uploads.")
    pdf.ln(2)
    pdf.bold_label("Right model for the right task. ",
                   "Frontier models handle deep reasoning (design, architecture). Fast models handle "
                   "well-constrained, pattern-heavy tasks (test generation, config). This reduces cost "
                   "by 5-10x on high-volume phases without sacrificing quality on critical ones.")
    pdf.ln(2)
    pdf.bold_label("Measured quality at every gate. ",
                   "Each phase gate has automated checks (run by the agent) and a scored rubric "
                   "(completed by the human reviewer). The evaluation record is appended to the "
                   "artifact, creating an audit trail and feedback loop for refining model assignments.")
    pdf.ln(2)
    pdf.bold_label("Security as a first-class sub-agent. ",
                   "Security is not a checklist applied after implementation -- it is the first "
                   "sub-agent dispatched. Permission sets, FLS, sharing rules, and encryption are "
                   "defined before any code is written.")
    pdf.ln(2)
    pdf.bold_label("Machine-readable quality gates. ",
                   "Evaluation artifacts and security matrices are produced as structured JSON using "
                   "Claude's structured outputs, then rendered as markdown for human readability. This "
                   "enables automated gate enforcement, programmatic FLS validation, and trend analysis.")

    # ===== 3. SYSTEM ARCHITECTURE =====
    pdf.h1("3. System Architecture")
    pdf.h2("3.1 Overall Flow")
    pdf.code(
        "User Request\n"
        "    |\n"
        "    v\n"
        "Triage: Trivial or Full SDLC?\n"
        "    |                    |\n"
        "    v                    v\n"
        "Quick Fix Agent     Phase 1: Discovery\n"
        "  (Fast tier)           | requirements.md\n"
        "                        v\n"
        "                    [Human Review + Evaluation Gate]\n"
        "                        v\n"
        "                    Phase 2: Design\n"
        "                        | design.md\n"
        "                        v\n"
        "                    [Human Review + Evaluation Gate]\n"
        "                        v\n"
        "                    Phase 3: Implementation\n"
        "                      1. Security Sub-Agent\n"
        "                      2. Apex Sub-Agent\n"
        "                      3. Integration Sub-Agent\n"
        "                      4. LWC Sub-Agent\n"
        "                      5. Config Sub-Agent\n"
        "                        | code + impl-summary.md\n"
        "                        v\n"
        "                    [Human Code Review + Eval Gate]\n"
        "                        v\n"
        "                    Phase 4: Testing\n"
        "                        | test-report.md\n"
        "                        v\n"
        "                    [Human QA Sign-off + Eval Gate]\n"
        "                        v\n"
        "                    Phase 5: Deployment\n"
        "                        | deploy-runbook.md\n"
        "                        v\n"
        "                    [Human Go/No-Go + Eval Gate]"
    )

    pdf.h2("3.2 Knowledge Architecture")
    pdf.p("Two MCP servers provide complementary knowledge:")
    pdf.table(
        ["MCP Server", "What It Provides", "Tools"],
        [
            ["Salesforce DX MCP (@salesforce/mcp)", "Live org data, metadata, LWC/SLDS knowledge, code analysis, test execution", "run_soql_query, deploy_metadata, guide_lwc_best_practices, run_code_analyzer, run_apex_test"],
            ["Local RAG MCP (mcp-local-rag)", "Industry cloud documentation, data models, business processes, regulations", "query_documents, ingest_file, list_files"],
        ],
        [2, 3, 3],
    )

    pdf.h2("3.3 Knowledge Resolution")
    pdf.table(
        ["Priority", "Source", "What It Provides"],
        [
            ["1a", "Salesforce DX MCP", "Live org data, metadata, LWC/SLDS knowledge, code analysis, test execution"],
            ["1b", "Local RAG MCP", "Industry cloud documentation, data models, business processes, regulations"],
            ["2", "Foundation rules", "Salesforce platform fundamentals (naming, security, governor limits)"],
            ["3", "Phase-specific rules", "Phase methodology and patterns (built into each agent's rule set)"],
        ],
        [1, 2, 4],
    )

    # ===== 3.4 MODEL SELECTION =====
    pdf.h2("3.4 Model Selection Strategy")
    pdf.p(
        "Not every phase requires the same model. High-reasoning tasks need frontier models. "
        "High-volume, well-constrained tasks can use faster and cheaper models. Each phase agent "
        "specifies its model in its SKILL.md."
    )
    pdf.h3("Model Tiers")
    pdf.table(
        ["Tier", "Models", "Characteristics"],
        [
            ["Frontier", "Claude Opus, o3", "Deep reasoning, multi-step planning, nuanced trade-offs. Highest cost/latency."],
            ["Balanced", "Claude Sonnet, GPT-4.1", "Strong code generation, good reasoning. ~3-5x cheaper than frontier."],
            ["Fast", "Claude Haiku, GPT-4.1-mini, Gemini Flash", "Pattern-following, template population. ~10-20x cheaper, ~3x faster."],
        ],
        [1, 2, 4],
    )
    pdf.h3("Phase-to-Model Assignment")
    pdf.table(
        ["Phase / Sub-Agent", "Tier", "Rationale"],
        [
            ["Discovery", "Frontier", "Nuanced understanding of business requirements, feasibility judgment"],
            ["Design", "Frontier", "Architecture decisions, Well-Architected assessment, security model design"],
            ["Impl Coordinator", "Frontier", "Cross-sub-agent orchestration, dependency ordering"],
            ["Impl: Security", "Balanced", "Permission set generation, FLS matrix, sharing rules"],
            ["Impl: Apex", "Balanced", "Code generation with well-defined patterns (trigger framework, service layer)"],
            ["Impl: Integration", "Balanced", "Callout patterns, Named Credentials, error handling"],
            ["Impl: LWC", "Balanced", "Component generation with SLDS/accessibility patterns"],
            ["Impl: Config", "Fast", "Declarative config is highly constrained (Flows, Validation Rules)"],
            ["Testing", "Fast + Balanced", "Fast for batch test gen (Message Batches API); balanced for strategy"],
            ["Deployment", "Fast", "Runbook generation, package.xml assembly are templated"],
            ["Quick Fix", "Fast", "Trivial changes with narrow scope"],
        ],
        [2, 1, 4],
    )

    pdf.h3("Extended Thinking")
    pdf.p(
        "Frontier-tier agents use Claude's extended thinking capability, which provides a dedicated "
        "reasoning scratchpad for multi-step trade-offs before producing the final artifact. Thinking "
        "blocks are saved as companion reasoning trace artifacts for reviewer audit."
    )
    pdf.table(
        ["Tier", "Thinking Config", "Budget"],
        [
            ["Frontier", "thinking: {type: enabled, budget_tokens: 20000}", "15,000-25,000 tokens"],
            ["Balanced", "Disabled", "--"],
            ["Fast", "Disabled", "--"],
        ],
        [1, 3, 2],
    )
    pdf.table(
        ["Phase", "Thinking Budget", "What Gets Reasoned Through"],
        [
            ["Discovery", "10-15K tokens", "Synthesizing org data + cloud docs; feasibility assessment"],
            ["Design", "15-25K tokens", "Config-First eval; Well-Architected trade-offs; security model"],
            ["Impl Coordinator", "5-10K tokens", "Sub-agent dispatch ordering; dependency analysis"],
        ],
        [2, 2, 4],
    )

    pdf.h3("Escalation Pattern")
    pdf.p(
        "If a fast-tier model produces output that fails the phase evaluation gate (Section 12), "
        "the phase is re-run with the next tier up: Fast -> Balanced -> Frontier. The evaluation "
        "artifact records which tier produced the passing output, providing data to refine tier "
        "assignments over time."
    )

    pdf.h3("SKILL.md Model Field")
    pdf.p(
        "Each agent's SKILL.md includes a model directive with optional thinking configuration. "
        "The Cursor Task tool reads this when spawning the agent."
    )
    pdf.code(
        "---\n"
        "model: opus\n"
        "fallback_model: sonnet\n"
        "thinking:\n"
        "  enabled: true\n"
        "  budget_tokens: 20000\n"
        "---"
    )

    # ===== 4. PHASE AGENTS =====
    pdf.h1("4. Phase Agents")

    pdf.h2("4.1 Phase 1: Discovery Agent")
    pdf.bold_label("Model tier: ", "Frontier (extended thinking: 10-15K budget)")
    pdf.bold_label("Purpose: ", "Understand the requirement, query the org, produce a structured requirements document.")
    pdf.ln(1)
    pdf.h3("Process")
    pdf.num(1, "Ask clarifying questions (functional, non-functional, constraints)")
    pdf.num(2, "Query org via DX MCP (run_soql_query) to discover existing objects, fields, automation")
    pdf.num(3, "Query Local RAG for cloud-specific business process documentation (with citations)")
    pdf.num(4, "Identify impacted objects and existing automation")
    pdf.num(5, "Assess: trivially solvable with configuration? (early exit to Quick Fix)")
    pdf.ln(1)
    pdf.h3("Output: requirements.md")
    pdf.bullet("Feature name, description, priority")
    pdf.bullet("Functional requirements (numbered with unique IDs)")
    pdf.bullet("Non-functional requirements (performance, security, accessibility)")
    pdf.bullet("Impacted objects and fields (from org query)")
    pdf.bullet("Existing automation found (from org query)")
    pdf.bullet("Constraints, assumptions, acceptance criteria")
    pdf.bullet("Sources (citations from RAG queries)")
    pdf.ln(1)
    pdf.bold_label("Reasoning trace: ", "requirements-reasoning.md (saved thinking blocks for audit)")
    pdf.ln(1)
    pdf.bold_label("Human Checkpoint: ", "Review requirements and optionally inspect reasoning trace. Approve or revise.")

    pdf.h2("4.2 Phase 2: Design Agent")
    pdf.bold_label("Model tier: ", "Frontier (extended thinking: 15-25K budget)")
    pdf.bold_label("Purpose: ", "Produce a solution design based on approved requirements.")
    pdf.ln(1)
    pdf.h3("Process")
    pdf.num(1, "Evaluate Configuration-First (Flow vs Apex vs Validation Rule vs Formula)")
    pdf.num(2, "If declarative: document the configuration approach")
    pdf.num(3, "If code needed: design data model, component architecture, integration points")
    pdf.num(4, "Query Local RAG for industry cloud data models and regulations (with citations)")
    pdf.num(5, "Query DX MCP for LWC best practices")
    pdf.num(6, "Assess against Well-Architected pillars (TRUSTED, EASY, ADAPTABLE)")
    pdf.num(7, "Identify which sub-agents are needed in Implementation")
    pdf.ln(1)
    pdf.h3("Output: design.md")
    pdf.bullet("Approach decision (declarative vs code, with rationale)")
    pdf.bullet("Data model changes (new objects/fields, ERD)")
    pdf.bullet("Component architecture (Apex, LWC, Flows)")
    pdf.bullet("Integration design (endpoints, auth, sync/async, error handling)")
    pdf.bullet("Security model (CRUD/FLS plan, sharing model, encryption needs)")
    pdf.bullet("Well-Architected assessment and risk assessment")
    pdf.bullet("Sources (citations from RAG and DX MCP queries)")
    pdf.ln(1)
    pdf.bold_label("Reasoning trace: ", "design-reasoning.md (thinking blocks showing architecture derivation)")
    pdf.ln(1)
    pdf.bold_label("Human Checkpoint: ", "Review design and reasoning trace. Approve architecture.")

    pdf.h2("4.3 Phase 3: Implementation Agent")
    pdf.bold_label("Purpose: ", "Build the solution per approved design. Coordinator dispatches to sub-agents.")
    pdf.ln(2)

    pdf.h3("Coordinator (Frontier tier, extended thinking: 5-10K budget)")
    pdf.bullet("Reads requirements.md + design.md")
    pdf.bullet("Dispatches sub-agents in dependency-aware order:")
    pdf.bullet("1. Security -> 2. Apex -> 3. Integration -> 4. LWC -> 5. Config", indent=5)
    pdf.bullet("Validates integration between sub-agent outputs")
    pdf.ln(1)

    pdf.h3("Security Sub-Agent (Balanced tier)")
    pdf.bold_label("Purpose: ", "Define permission model before any code is written.")
    pdf.bullet("Object-level, field-level, and record-level security")
    pdf.bullet("Permission Set and Permission Set Group definitions")
    pdf.bullet("Shield Platform Encryption for PII/PHI fields")
    pdf.bullet("FLS matrix produced as structured JSON (see Section 12.8)")
    pdf.ln(1)

    pdf.h3("Apex Sub-Agent (Balanced tier)")
    pdf.bullet("DX MCP: run_code_analyzer, scan_apex_class_for_antipatterns")
    pdf.bullet("References security model: all data access uses WITH USER_MODE or stripInaccessible()")
    pdf.bullet("Produces: Apex classes/triggers with naming, security enforcement, bulkification")
    pdf.ln(1)

    pdf.h3("Integration Sub-Agent (Balanced tier)")
    pdf.bold_label("Purpose: ", "Handle all external system integrations.")
    pdf.bullet("Named Credentials, callout patterns, error handling, Platform Events, CDC")
    pdf.bullet("Async patterns (Queueable callouts, chaining, idempotency)")
    pdf.bullet("Produces: Callout classes, Event defs, error utilities, HttpCalloutMock")
    pdf.ln(1)

    pdf.h3("LWC Sub-Agent (Balanced tier)")
    pdf.bullet("DX MCP: guide_lwc_development, explore_lbc_components, explore_slds_blueprints")
    pdf.bullet("Produces: LWC components with SLDS styling, accessibility, FLS-aware rendering")
    pdf.ln(1)

    pdf.h3("Config Sub-Agent (Fast tier)")
    pdf.bullet("DX MCP: retrieve_metadata (check existing flows)")
    pdf.bullet("Produces: Flow definitions, validation rules, config instructions")
    pdf.ln(1)

    pdf.h3("Output: impl-summary.md")
    pdf.bullet("Files created/modified with paths and responsibilities")
    pdf.bullet("Integration points, security model, component dependencies")
    pdf.ln(1)
    pdf.bold_label("Human Checkpoint: ", "Code review using Implementation Evaluation rubric (Section 12.4).")

    pdf.h2("4.4 Phase 4: Testing Agent")
    pdf.bold_label("Model tier: ", "Balanced (strategy) + Fast (batch generation via Message Batches API)")
    pdf.bold_label("Purpose: ", "Produce test classes, test plans, and validate coverage.")
    pdf.ln(1)
    pdf.h3("Phase A: Test Strategy (balanced tier)")
    pdf.num(1, "Analyze all Apex classes, LWC components, and integration endpoints")
    pdf.num(2, "Create test plan (positive, negative, bulk, edge, security, integration)")
    pdf.num(3, "Produce test manifest listing all test classes to generate")
    pdf.ln(1)
    pdf.h3("Phase B: Batch Generation (fast tier, Message Batches API)")
    pdf.num(4, "Submit all test class generation requests as a single Claude Message Batch")
    pdf.num(5, "Each request includes: source class + test data factory + testing rules")
    pdf.num(6, "Batch completes asynchronously; 50% cost reduction vs sequential calls")
    pdf.ln(1)
    pdf.h3("Phase C: Validation")
    pdf.num(7, "Execute all tests via DX MCP (run_apex_test)")
    pdf.num(8, "Validate production readiness (validate_and_optimize, score_issues)")
    pdf.num(9, "If failures, regenerate individual tests (not batch)")
    pdf.ln(1)
    pdf.h3("Output: test-report.md")
    pdf.bullet("Test classes, test plan, coverage per class, production readiness score")
    pdf.bullet("Batch generation metadata (batch ID, completion time, per-request status)")
    pdf.ln(1)
    pdf.bold_label("Human Checkpoint: ", "QA sign-off using Testing Evaluation rubric (Section 12.5).")

    pdf.h2("4.5 Phase 5: Deployment Agent")
    pdf.bold_label("Model tier: ", "Fast")
    pdf.bold_label("Purpose: ", "Prepare deployment package and runbook.")
    pdf.ln(1)
    pdf.h3("Output: deploy-runbook.md")
    pdf.bullet("Deployment method, pre/post steps, commands, rollback plan, smoke tests")
    pdf.bullet("Permission set and sharing rule deployment included in package")
    pdf.ln(1)
    pdf.bold_label("Human Checkpoint: ", "Go/no-go using Deployment Evaluation rubric (Section 12.6).")

    pdf.h2("4.6 Quick Fix Agent")
    pdf.bold_label("Model tier: ", "Fast")
    pdf.bold_label("Purpose: ", "Handle trivial tasks that do not warrant the full 5-phase pipeline.")
    pdf.ln(1)
    pdf.bold_label("Scope: ", "Typo fixes, simple renames, single field additions, simple validation rules.")
    pdf.ln(1)
    pdf.bold_label("Guardrail: ", "If non-trivial, redirect to Phase 1: Discovery.")

    # ===== 5. KNOWLEDGE LAYER =====
    pdf.h1("5. Knowledge Layer")

    pdf.h2("5.1 Salesforce DX MCP Server (Official)")
    pdf.p(
        "The official Salesforce DX MCP Server (@salesforce/mcp), released as part of Salesforce "
        "Headless 360 (April 2026), provides 60+ tools."
    )
    pdf.table(
        ["Toolset", "Key Tools", "Used By"],
        [
            ["orgs", "list_all_orgs, create_scratch_org", "Discovery, Deployment"],
            ["metadata", "deploy_metadata, retrieve_metadata", "Impl (all), Deployment"],
            ["data", "run_soql_query", "Discovery, Impl, Security"],
            ["lwc-experts", "guide_lwc_best_practices, explore_lbc_components", "Design, Impl (LWC)"],
            ["code-analysis", "run_code_analyzer, scan_apex_class", "Impl (Apex), Testing"],
            ["testing", "run_apex_test, run_agent_test", "Testing"],
            ["experts-validation", "validate_and_optimize, score_issues", "Testing"],
            ["devops", "commit/promote_devops_center_work_item", "Deployment"],
        ],
        [2, 4, 2],
    )

    pdf.h2("5.2 Local RAG MCP Server + Citations")
    pdf.p(
        "The DX MCP does not cover industry cloud-specific knowledge. "
        "This gap is filled by mcp-local-rag (v0.12.0), a zero-setup local RAG server."
    )
    pdf.bullet("Runs entirely locally (no API keys, no cloud dependency)")
    pdf.bullet("Supports PDF, Markdown, TXT, DOCX")
    pdf.bullet("Semantic search with keyword boosting")
    pdf.ln(1)
    pdf.p(
        "Citations integration: RAG results are passed to Claude as document content blocks with "
        "citations: {enabled: true}. Claude's response includes character-level citations back to "
        "source documents. Every claim about a cloud data model or regulation is traceable."
    )

    pdf.h2("5.3 Documentation Registry and Fetcher")
    pdf.p(
        "A JSON registry (sf-docs-registry.json) maps each cloud to its official documentation. "
        "A Python CLI (sf-docs-fetch.py) downloads documentation automatically."
    )

    pdf.h2("5.4 Foundation Rules")
    pdf.table(
        ["Rule File", "Content"],
        [
            ["naming-conventions.md", "PascalCase objects, camelCase methods, trigger naming, LWC naming"],
            ["security-baseline.md", "CRUD/FLS enforcement, WITH USER_MODE, sharing rules, bind variables"],
            ["governor-limits.md", "100 SOQL queries (sync), 10K DML rows, bulkification, async patterns"],
        ],
        [2, 5],
    )

    pdf.h2("5.7 Prompt Caching Strategy")
    pdf.p(
        "Every agent loads foundation rules (~15-20KB) plus phase-specific rules. Claude's prompt "
        "caching marks these as cache_control: {type: ephemeral}. The first agent pays a 25% write "
        "premium; subsequent agents read at 90% discount."
    )
    pdf.table(
        ["Agent", "Foundation Rules", "Phase Rules", "Cache Benefit"],
        [
            ["Discovery", "WRITE", "WRITE (phase-1)", "--"],
            ["Design", "READ", "WRITE (phase-2)", "foundation: 90% off"],
            ["Impl Coordinator", "READ", "WRITE (phase-3)", "foundation: 90% off"],
            ["Impl: Security", "READ", "READ (phase-3)", "both: 90% off"],
            ["Impl: Apex", "READ", "READ (phase-3)", "both: 90% off"],
            ["Impl: Integration", "READ", "READ (phase-3)", "both: 90% off"],
            ["Impl: LWC", "READ", "READ (phase-3)", "both: 90% off"],
            ["Impl: Config", "READ", "READ (phase-3)", "both: 90% off"],
            ["Testing", "READ", "WRITE (phase-4)", "foundation: 90% off"],
            ["Deployment", "READ", "WRITE (phase-5)", "foundation: 90% off"],
        ],
        [2, 2, 2, 2],
    )
    pdf.p(
        "Net input token cost reduction on rule content: ~60-70%. Cache TTL is 5 minutes "
        "(effective within the Implementation phase's rapid sub-agent sequence). Across phases "
        "separated by human review, cache expires and is re-written."
    )

    # ===== 6. ARTIFACT HANDOFF =====
    pdf.h1("6. Artifact Handoff System")
    pdf.p(
        "Artifacts are the contract between phases. Each phase agent produces a structured markdown "
        "file that the next phase reads as input. Each artifact includes an Evaluation section "
        "appended by the reviewer. Cursor hooks (Section 8) enforce prerequisite validation."
    )
    pdf.code(
        "Discovery --> requirements.md --> [Eval Gate] --> Design\n"
        "Design    --> design.md       --> [Eval Gate] --> Implementation\n"
        "Impl      --> impl-summary.md --> [Eval Gate] --> Testing\n"
        "Testing   --> test-report.md  --> [Eval Gate] --> Deployment\n"
        "Deploy    --> deploy-runbook.md --> [Eval Gate] --> Done"
    )

    # ===== 7. DIRECTORY STRUCTURE =====
    pdf.h1("7. Directory Structure")
    pdf.code(
        ".cursor/\n"
        "|-- rules/\n"
        "|   |-- foundation/ (naming, security, governor-limits)\n"
        "|   |-- phase-1-discovery.md .. phase-5-deployment.md\n"
        "|   |-- quick-fix.md\n"
        "|   +-- active-project-context.md\n"
        "|\n"
        "|-- skills/\n"
        "|   |-- discovery/SKILL.md\n"
        "|   |-- design/SKILL.md\n"
        "|   |-- implementation/SKILL.md\n"
        "|   |   |-- security/  apex/  integration/\n"
        "|   |   |-- lwc/  config/\n"
        "|   |-- testing/ deployment/ quick-fix/\n"
        "|   +-- _shared/knowledge-query-pattern.md\n"
        "|\n"
        "|-- artifacts/templates/ (+ {feature-name}/)\n"
        "|-- knowledge/ (registry + cloud docs)\n"
        "|-- hooks.json\n"
        "|-- hooks/ (validate-phase-gate.sh,\n"
        "|          log-agent-metrics.sh,\n"
        "|          validate-artifact-schema.sh)\n"
        "+-- tools/ (sf-docs-fetch.py, etc.)"
    )

    # ===== 8. CURSOR HOOKS =====
    pdf.h1("8. Cursor Hooks Configuration")
    pdf.p(
        "Cursor hooks automate and enforce the phase pipeline. They run as spawned processes "
        "at defined stages of the agent loop, communicating via JSON over stdio."
    )
    pdf.h3("Hook Events")
    pdf.table(
        ["Hook Event", "Purpose"],
        [
            ["sessionStart", "Verify prerequisite artifacts exist with APPROVED gate decision"],
            ["afterFileEdit", "Auto-validate artifact against JSON schema on save"],
            ["subagentStart", "Log sub-agent invocation with model tier for cost tracking"],
            ["stop", "Verify output artifact created; validate schema; log metrics"],
        ],
        [2, 5],
    )
    pdf.h3("Phase Gate Enforcement")
    pdf.table(
        ["Phase Agent", "Required Prerequisite"],
        [
            ["Design", "requirements.md + evaluation.json with APPROVED"],
            ["Implementation", "design.md + evaluation.json with APPROVED"],
            ["Testing", "impl-summary.md + evaluation.json with APPROVED"],
            ["Deployment", "test-report.md + evaluation.json with APPROVED"],
            ["Discovery / Quick Fix", "No prerequisites"],
        ],
        [2, 5],
    )
    pdf.h3("Metrics Logging")
    pdf.p(
        "Every invocation is logged to metrics.jsonl (one JSON line per invocation) with: "
        "timestamp, agent name, model tier, thinking budget, input/output/thinking tokens, "
        "cache status, duration, and gate decision. This enables cost analysis, model tier "
        "optimization, and cache hit rate tracking."
    )

    # ===== 9. MCP CONFIG =====
    pdf.h1("9. MCP Configuration")
    pdf.code(
        '{\n'
        '  "mcpServers": {\n'
        '    "Salesforce DX": {\n'
        '      "command": "npx",\n'
        '      "args": ["-y", "@salesforce/mcp",\n'
        '        "--orgs", "DEFAULT_TARGET_ORG",\n'
        '        "--toolsets", "orgs,metadata,data,users,\n'
        '          lwc-experts,code-analysis,testing,\n'
        '          experts-validation,devops",\n'
        '        "--allow-non-ga-tools"]\n'
        '    },\n'
        '    "sf-knowledge": {\n'
        '      "command": "npx",\n'
        '      "args": ["-y", "mcp-local-rag"],\n'
        '      "env": { "BASE_DIR": ".cursor/knowledge" }\n'
        '    }\n'
        '  }\n'
        '}'
    )

    # ===== 10. EXTENDING =====
    pdf.h1("10. Extending to New Salesforce Clouds")
    pdf.p("Adding support for a new cloud requires three steps:")
    pdf.num(1, "Update sf-docs-registry.json with PDF slugs (~5 min)")
    pdf.num(2, "Run python .cursor/tools/sf-docs-fetch.py --cloud {name} (~1 min)")
    pdf.num(3, "Query immediately -- RAG server auto-indexes new docs")
    pdf.p("No code changes. No account dependencies. No manual uploads.")

    # ===== 11. CONTEXT BUDGET =====
    pdf.h1("11. Context Budget Analysis")
    pdf.table(
        ["Agent", "Tier", "Thinking", "Cache", "Est. Context"],
        [
            ["Discovery", "Frontier", "10-15K", "WRITE", "~40KB"],
            ["Design", "Frontier", "15-25K", "READ fnd", "~60KB"],
            ["Impl Coord", "Frontier", "5-10K", "READ fnd", "~50KB"],
            ["Impl: Security", "Balanced", "--", "READ both", "~45KB"],
            ["Impl: Apex", "Balanced", "--", "READ both", "~60KB"],
            ["Impl: Integ", "Balanced", "--", "READ both", "~55KB"],
            ["Impl: LWC", "Balanced", "--", "READ both", "~55KB"],
            ["Impl: Config", "Fast", "--", "READ both", "~35KB"],
            ["Testing", "Fast+Bal", "--", "READ fnd", "~65KB"],
            ["Deployment", "Fast", "--", "READ fnd", "~40KB"],
            ["Quick Fix", "Fast", "--", "WRITE", "~30KB"],
        ],
        [2, 1, 1, 2, 1],
    )
    pdf.p(
        "Each sub-agent uses 30-65KB. Knowledge queries happen on-demand via MCP. "
        "Prompt caching reduces rule-content costs by ~60-70%. Extended thinking adds "
        "reasoning tokens for frontier-tier agents (billed separately from context window)."
    )

    # ===== 12. EVALUATION FRAMEWORK =====
    pdf.h1("12. Phase Evaluation Framework")
    pdf.p(
        "Each phase gate combines automated checks (run by the agent before human review) with "
        "a structured rubric (scored by the human reviewer). Evaluation artifacts are produced "
        "as structured JSON (Section 12.8) for programmatic gate enforcement via hooks."
    )
    pdf.h3("Evaluation Structure")
    pdf.num(1, "Automated checks -- agent runs before presenting output. Failures block handoff.")
    pdf.num(2, "Rubric -- scored criteria, each rated Pass / Partial / Fail by human reviewer.")
    pdf.num(3, "Gate rule -- minimum conditions to proceed to next phase.")
    pdf.num(4, "Evaluation record -- structured JSON (evaluation.json) + markdown in artifact.")

    pdf.h2("12.2 Discovery Evaluation")
    pdf.h3("Rubric")
    pdf.table(
        ["Criterion", "Pass", "Fail"],
        [
            ["Completeness", "All user scenarios covered", "Major user flows missing"],
            ["Clarity", "Unambiguous, testable requirements", "Vague or contradictory"],
            ["Feasibility", "Constraints and risks identified", "No feasibility analysis"],
            ["Traceability", "Unique IDs, links to user story", "No traceability"],
            ["Org Awareness", "Existing objects/automation documented", "No org query performed"],
            ["Reasoning Transparency", "Thinking trace shows clear synthesis", "No thinking trace"],
        ],
        [2, 3, 3],
    )
    pdf.bold_label("Gate: ", "Zero Fail. Max 1 Partial.")

    pdf.h2("12.3 Design Evaluation")
    pdf.h3("Rubric")
    pdf.table(
        ["Criterion", "Pass", "Fail"],
        [
            ["Architecture Soundness", "Well-Architected pillars scored with evidence", "No assessment"],
            ["Security Completeness", "CRUD/FLS plan, sharing model, encryption", "No security analysis"],
            ["Scalability", "Governor limit analysis, bulk data considered", "No scalability thought"],
            ["Maintainability", "Separation of concerns, clear boundaries", "Tightly coupled design"],
            ["Integration Design", "All external touchpoints with auth/error handling", "Not analyzed"],
            ["Reasoning Transparency", "Thinking trace shows Config-First eval", "No thinking trace"],
        ],
        [2, 3, 3],
    )
    pdf.bold_label("Gate: ", "All 3 Well-Architected pillars scored. Security has CRUD/FLS + sharing. Zero Fail.")

    pdf.h2("12.4 Implementation Evaluation")
    pdf.h3("Rubric")
    pdf.table(
        ["Criterion", "Pass", "Fail"],
        [
            ["Code Quality", "Clean, DRY, ApexDoc on public methods", "Duplicated logic, no docs"],
            ["Security: CRUD/FLS", "Every data access enforces CRUD/FLS", "Access without enforcement"],
            ["Security: Integration", "Named Credentials, no secrets in code", "Hardcoded endpoints"],
            ["Bulkification", "Collections-based, no SOQL/DML in loops", "SOQL or DML in loops"],
            ["Integration Robustness", "Error handling, retry, timeout", "No error handling"],
            ["Permission Model", "Perm sets + FLS matrix + OWD documented", "No perm metadata"],
        ],
        [2, 3, 3],
    )
    pdf.bold_label("Gate: ", "Code analyzer passes. Zero anti-patterns. All security checks pass. Zero Fail.")

    pdf.h2("12.5 Testing Evaluation")
    pdf.h3("Rubric")
    pdf.table(
        ["Criterion", "Pass", "Fail"],
        [
            ["Coverage Depth", "Meaningful assertions, bulk + negative", "Line coverage only"],
            ["Edge Cases", "Null handling, governor boundary", "No edge case testing"],
            ["Security Tests", "System.runAs() with restricted profiles", "No security-context testing"],
            ["Integration Tests", "Mock all endpoints + error responses", "No callout mocks"],
            ["Regression Safety", "Test data factory, independent tests", "Hard-coded IDs"],
        ],
        [2, 3, 3],
    )
    pdf.bold_label("Gate: ", "75% coverage per class. All green. Readiness above threshold. Zero Fail.")

    pdf.h2("12.6 Deployment Evaluation")
    pdf.h3("Rubric")
    pdf.table(
        ["Criterion", "Pass", "Fail"],
        [
            ["Runbook Completeness", "Pre/post/rollback steps", "Missing rollback"],
            ["Environment Coverage", "Sandbox validation planned", "No sandbox plan"],
            ["Rollback Plan", "Step-by-step, tested in sandbox", "No rollback plan"],
            ["Permission Deployment", "Perm sets + sharing in package", "Security metadata missing"],
        ],
        [2, 3, 3],
    )
    pdf.bold_label("Gate: ", "Validation deploy succeeds. Rollback documented. Zero Fail.")

    pdf.h2("12.7 Evaluation Record Format")
    pdf.p("Evaluation is produced as structured JSON (evaluation.json) and rendered as markdown:")
    pdf.code(
        "## Evaluation\n"
        "Evaluator: [Name]  |  Date: [Date]  |  Model: [Tier]\n"
        "Automated Checks: [x] All passed\n"
        "Rubric: Completeness=Pass, Clarity=Pass, ...\n"
        "Gate Decision: APPROVED / REVISE / ESCALATE\n"
        "Notes: [Free-form reviewer notes]"
    )

    pdf.h2("12.8 Structured Output Schemas")
    pdf.p(
        "Evaluation artifacts and FLS matrices use Claude's structured outputs "
        "(output_config.format: {type: json_schema}) to guarantee valid, machine-parseable output."
    )
    pdf.h3("Evaluation Schema (all phases)")
    pdf.code(
        '{\n'
        '  "phase": "discovery|design|impl|testing|deploy",\n'
        '  "model_tier_used": "frontier|balanced|fast",\n'
        '  "thinking_budget_used": 15000,\n'
        '  "automated_checks": [\n'
        '    {"check": "...", "passed": true, "notes": "..."}\n'
        '  ],\n'
        '  "rubric_scores": [\n'
        '    {"criterion": "...", "score": "Pass|Partial|Fail"}\n'
        '  ],\n'
        '  "gate_decision": "APPROVED|REVISE|ESCALATE",\n'
        '  "citations_count": 12\n'
        '}'
    )
    pdf.h3("FLS Matrix Schema (Security Sub-Agent)")
    pdf.code(
        '{\n'
        '  "fields": [\n'
        '    {\n'
        '      "object_field": "Policy__c.Premium__c",\n'
        '      "encrypted": false,\n'
        '      "permission_sets": [\n'
        '        {"name": "Agent", "access": "Read"},\n'
        '        {"name": "Manager", "access": "Read/Edit"}\n'
        '      ]\n'
        '    }\n'
        '  ]\n'
        '}'
    )
    pdf.p(
        "JSON artifacts enable: automated gate enforcement via hooks, FLS validation by diffing "
        "against actual permission set metadata from DX MCP, and trend analysis across projects."
    )

    # ===== 13. ROADMAP =====
    pdf.h1("13. Implementation Roadmap")

    pdf.h2("Phase A: Foundation (Week 1)")
    pdf.num(1, "Create foundation/ rules (naming, security, governor limits)")
    pdf.num(2, "Create artifact templates with evaluation sections and Sources sections")
    pdf.num(3, "Build evaluation rubric templates with structured output JSON schemas")
    pdf.num(4, "Configure Salesforce DX MCP Server")
    pdf.num(5, "Authorize a Salesforce org")
    pdf.num(6, "Implement Cursor hooks (hooks.json + hook scripts)")

    pdf.h2("Phase B: Knowledge Layer (Week 1-2)")
    pdf.num(7, "Create sf-docs-registry.json")
    pdf.num(8, "Build sf-docs-fetch.py CLI tool")
    pdf.num(9, "Download documentation for active cloud")
    pdf.num(10, "Configure mcp-local-rag")
    pdf.num(11, "Create _shared/knowledge-query-pattern.md with citations integration")

    pdf.h2("Phase C: Phase Agents + Claude API Features (Week 2-3)")
    pdf.num(12, "Build Discovery agent (frontier, extended thinking, citations, prompt caching)")
    pdf.num(13, "Build Design agent (frontier, extended thinking, citations, prompt caching)")
    pdf.num(14, "Build Implementation coordinator + sub-agents:")
    pdf.bullet("Security (balanced, structured output FLS JSON)", indent=10)
    pdf.bullet("Apex (balanced), Integration (balanced, citations), LWC (balanced), Config (fast)", indent=10)
    pdf.num(15, "Build Testing agent (balanced strategy + fast batch generation via Message Batches)")
    pdf.num(16, "Build Deployment agent (fast)")
    pdf.num(17, "Build Quick Fix agent (fast)")

    pdf.h2("Phase D: Validation (Week 3-4)")
    pdf.num(18, "Run real feature through all 5 phases with evaluation gates and hooks")
    pdf.num(19, "Validate extended thinking (reasoning traces saved, quality improvement)")
    pdf.num(20, "Validate prompt caching (cache hits during Impl sub-agents, cost reduction)")
    pdf.num(21, "Validate batch generation (parallel test gen, coverage met)")
    pdf.num(22, "Validate citations (traceable source references in artifacts)")
    pdf.num(23, "Validate hooks (phase gate blocks without APPROVED; metrics logged)")
    pdf.num(24, "Validate structured outputs (JSON schemas, FLS diff against metadata)")
    pdf.num(25, "Validate cloud extensibility (add second cloud)")
    pdf.num(26, "Refine rules, rubrics, model assignments, thinking budgets, templates")

    # ===== 14. RETROFITTING EXISTING PROJECTS =====
    pdf.h1("14. Retrofitting Existing Projects")
    pdf.p(
        "The pipeline described in Sections 4-6 assumes a greenfield flow. Real-world adoption "
        "requires plugging into projects that are already mid-flight -- requirements may exist in "
        "Jira, design decisions in Confluence, and code may already be partially written."
    )

    pdf.h2("14.1 Mid-Pipeline Entry Points")
    pdf.p(
        "The ADLC pipeline supports entry at any phase. The constraint: all prerequisite artifacts "
        "must exist and pass evaluation before a phase can start. For existing projects, this means "
        "generating artifacts retroactively from existing documentation."
    )
    pdf.table(
        ["Current State", "Artifacts to Generate", "Resume At"],
        [
            ["Pre-Discovery", "None (run Discovery normally)", "Phase 1"],
            ["Post-Discovery", "requirements.md", "Phase 2: Design"],
            ["Post-Design", "requirements.md + design.md", "Phase 3: Impl"],
            ["Post-Implementation", "All three + fls-matrix.json", "Phase 4: Testing"],
            ["Post-Testing", "All four + test-report.md", "Phase 5: Deploy"],
        ],
        [2, 3, 2],
    )

    pdf.h2("14.2 Retrofit Agent (Balanced tier)")
    pdf.p(
        "A dedicated agent that translates existing project documentation (Jira stories, "
        "Confluence pages, Word/PDF docs) into ADLC-compliant artifacts. It is not Discovery "
        "or Design -- it is a translation and extraction agent."
    )
    pdf.h3("Process")
    pdf.num(1, "Ingest existing documentation into Local RAG via ingest_file")
    pdf.num(2, "Query the org via DX MCP to discover current state (objects, fields, automation, code)")
    pdf.num(3, "Cross-reference existing docs against org state")
    pdf.num(4, "Generate the required artifact(s) using ADLC templates, with citations to source docs")
    pdf.num(5, "Produce gap-analysis.md listing what's missing")
    pdf.ln(1)
    pdf.p(
        "Citations are enabled: every generated requirement or design decision cites back to "
        "the source Jira story or Confluence page, making the generated artifacts auditable."
    )

    pdf.h2("14.3 Gap Analysis")
    pdf.p(
        "The Retrofit Agent always produces a gap-analysis.md alongside generated artifacts, "
        "listing missing information across five categories:"
    )
    pdf.bullet("Requirement gaps: stories without acceptance criteria, missing NFRs")
    pdf.bullet("Design gaps: no Config-First assessment, no Well-Architected review")
    pdf.bullet("Security gaps: no sharing model, no FLS matrix, missing CRUD/FLS enforcement in code")
    pdf.bullet("Integration gaps: endpoints without Named Credentials, no error handling")
    pdf.bullet("Testing gaps: Apex classes with 0% coverage, no bulk or security tests")
    pdf.ln(1)
    pdf.p(
        "Each gap is classified as blocker (must fill before proceeding) or acceptable risk "
        "(proceed with gap documented). The human reviewer makes the final call."
    )

    pdf.h2("14.4 Retroactive Evaluation")
    pdf.p(
        "Generated artifacts go through the same evaluation framework (Section 12) with one "
        "additional gate decision option:"
    )
    pdf.table(
        ["Gate Decision", "Meaning"],
        [
            ["APPROVED", "Artifact meets all criteria. Proceed."],
            ["APPROVED_WITH_GAPS", "Minimum criteria met; gaps documented as risks. Proceed."],
            ["REVISE", "Critical issues. Fill gaps and re-generate."],
            ["ESCALATE", "Fundamental problems requiring stakeholder decision."],
        ],
        [2, 5],
    )
    pdf.p(
        "APPROVED_WITH_GAPS is only available for retroactively generated artifacts. When used, "
        "the gap-analysis.md travels with the artifacts as a risk register. Once all gaps are "
        "resolved, the project transitions to the standard pipeline."
    )

    pdf.h2("14.5 Existing Code Onboarding")
    pdf.p(
        "When entering at Post-Implementation (code already exists), the Retrofit Agent runs "
        "a reverse-engineering pass:"
    )
    pdf.num(1, "DX MCP: run_code_analyzer + scan_apex_class on all Apex classes")
    pdf.num(2, "DX MCP: retrieve_metadata for permission sets, sharing rules, OWD, objects, flows")
    pdf.num(3, "DX MCP: run_soql_query to map object relationships and record counts")
    pdf.num(4, "Generate fls-matrix.json from actual deployed permission set metadata")
    pdf.num(5, "Generate impl-summary.md from actual code + metadata")
    pdf.num(6, "Flag: code quality issues, missing CRUD/FLS, hardcoded creds, untested classes")

    pdf.h2("14.6 Hook Behavior for Retrofit")
    pdf.p(
        "The sessionStart hook supports a retrofit mode flag. When set, the hook accepts "
        "APPROVED_WITH_GAPS as a valid gate decision (in addition to APPROVED) and logs "
        "the entry as a retrofit in metrics.jsonl for adoption tracking."
    )

    # ===== END =====
    pdf.ln(8)
    pdf.set_draw_color(20, 60, 120)
    pdf.line(60, pdf.get_y(), pdf.w - 60, pdf.get_y())
    pdf.ln(4)
    pdf.set_font("Helvetica", "I", 9)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(0, 5, "End of Document", align="C")

    out = "/Users/janantharaman/Documents/LKInsurance/ADLC-for-Salesforce.pdf"
    pdf.output(out)
    print(f"PDF generated: {out}")
    print(f"Pages: {pdf.page_no()}")


if __name__ == "__main__":
    build()
