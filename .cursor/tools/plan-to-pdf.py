#!/usr/bin/env python3
"""Convert the Phase-Based SDLC Agent Architecture plan to PDF."""

import textwrap
from fpdf import FPDF


class PlanPDF(FPDF):
    def __init__(self):
        super().__init__()
        self.add_page()
        self.set_auto_page_break(auto=True, margin=20)
        self.set_margins(20, 20, 20)

    def header(self):
        if self.page_no() > 1:
            self.set_font("Helvetica", "I", 8)
            self.set_text_color(130, 130, 130)
            self.cell(0, 8, "Phase-Based SDLC Agent Architecture", align="R")
            self.ln(4)
            self.set_draw_color(200, 200, 200)
            self.line(20, self.get_y(), self.w - 20, self.get_y())
            self.ln(6)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(130, 130, 130)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="C")

    def title_page(self):
        self.ln(50)
        self.set_font("Helvetica", "B", 28)
        self.set_text_color(20, 60, 120)
        self.multi_cell(0, 14, "Phase-Based SDLC\nAgent Architecture")
        self.ln(8)
        self.set_draw_color(20, 60, 120)
        self.line(60, self.get_y(), self.w - 60, self.get_y())
        self.ln(10)
        self.set_font("Helvetica", "", 13)
        self.set_text_color(80, 80, 80)
        self.multi_cell(0, 7, "Redesigning Cursor AI configuration from flat skills\nto phase-based SDLC agents with structured handoffs")
        self.ln(20)
        self.set_font("Helvetica", "", 11)
        self.set_text_color(100, 100, 100)
        self.cell(0, 7, "LKInsurance Project", align="C")
        self.ln(7)
        self.cell(0, 7, "April 2026", align="C")
        self.add_page()

    def section_heading(self, text, level=1):
        self.ln(4)
        if level == 1:
            self.set_font("Helvetica", "B", 18)
            self.set_text_color(20, 60, 120)
            self.multi_cell(0, 10, text)
            self.set_draw_color(20, 60, 120)
            self.line(20, self.get_y(), self.w - 20, self.get_y())
            self.ln(4)
        elif level == 2:
            self.set_font("Helvetica", "B", 14)
            self.set_text_color(40, 80, 140)
            self.multi_cell(0, 8, text)
            self.ln(2)
        elif level == 3:
            self.set_font("Helvetica", "B", 12)
            self.set_text_color(60, 60, 60)
            self.multi_cell(0, 7, text)
            self.ln(1)

    def body_text(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_text_color(40, 40, 40)
        self.multi_cell(0, 5.5, text)
        self.ln(2)

    def bold_text(self, label, value):
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

    def numbered_item(self, num, text):
        self.set_x(25)
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(20, 60, 120)
        self.cell(8, 5.5, f"{num}.")
        self.set_font("Helvetica", "", 10)
        self.set_text_color(40, 40, 40)
        self.multi_cell(0, 5.5, text)
        self.ln(1)

    def code_block(self, text):
        self.set_fill_color(245, 245, 245)
        self.set_draw_color(200, 200, 200)
        self.set_font("Courier", "", 8.5)
        self.set_text_color(50, 50, 50)
        lines = text.strip().split("\n")
        x = 25
        y_start = self.get_y()
        max_w = self.w - 45
        block_h = len(lines) * 4.5 + 4
        if y_start + block_h > self.h - 25:
            self.add_page()
            y_start = self.get_y()
        self.rect(x - 2, y_start - 1, max_w + 4, block_h, style="DF")
        self.set_xy(x, y_start + 1)
        for line in lines:
            self.set_x(x)
            self.cell(max_w, 4.5, line[:95])
            self.ln(4.5)
        self.ln(3)

    def table(self, headers, rows, col_widths=None):
        usable = self.w - 40
        col_count = len(headers)
        if col_widths is None:
            if col_count >= 3:
                col_widths = [usable * 0.22, usable * 0.45, usable * 0.33]
            elif col_count == 2:
                col_widths = [usable * 0.35, usable * 0.65]
            else:
                col_widths = [usable / col_count] * col_count

        self.set_font("Helvetica", "B", 9)
        self.set_fill_color(20, 60, 120)
        self.set_text_color(255, 255, 255)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 7, h, border=1, fill=True, align="C")
        self.ln()

        self.set_text_color(40, 40, 40)
        fill = False
        for row in rows:
            if fill:
                self.set_fill_color(240, 245, 250)
            else:
                self.set_fill_color(255, 255, 255)
            max_lines = 1
            cell_texts = []
            for i, cell in enumerate(row):
                chars = int(col_widths[i] / 1.9)
                wrapped = textwrap.wrap(cell, width=max(chars, 15))
                if not wrapped:
                    wrapped = [""]
                cell_texts.append(wrapped)
                max_lines = max(max_lines, len(wrapped))
            row_h = max_lines * 4.5
            if self.get_y() + row_h > self.h - 25:
                self.add_page()
            y_start = self.get_y()
            x_pos = 20
            for i, texts in enumerate(cell_texts):
                self.set_xy(x_pos, y_start)
                self.rect(x_pos, y_start, col_widths[i], row_h, style="DF")
                self.set_font("Helvetica", "", 8.5)
                for j, line in enumerate(texts):
                    self.set_xy(x_pos + 1, y_start + j * 4.5 + 0.5)
                    self.cell(col_widths[i] - 2, 4.5, line[:70])
                x_pos += col_widths[i]
            self.set_y(y_start + row_h)
            fill = not fill
        self.ln(4)


def build_pdf():
    pdf = PlanPDF()
    pdf.alias_nb_pages()

    # === Title Page ===
    pdf.title_page()

    # === Table of Contents ===
    pdf.section_heading("Table of Contents")
    toc = [
        "1. Architecture Overview",
        "2. Directory Structure",
        "3. Context Budget per Agent",
        "4. Phase 1: Discovery Agent",
        "5. Phase 2: Design Agent",
        "6. Phase 3: Implementation Agent (Coordinator + Sub-Agents)",
        "7. Phase 4: Testing Agent",
        "8. Phase 5: Deployment Agent",
        "9. Quick Fix Agent",
        "10. What to Keep, Consolidate, or Remove",
        "11. Artifact Templates",
        "12. Migration Path",
    ]
    for item in toc:
        pdf.bullet(item)
    pdf.add_page()

    # === 1. Architecture Overview ===
    pdf.section_heading("1. Architecture Overview")
    pdf.body_text(
        "Replace the current flat skill + always-on rules model with a 6-agent system organized "
        "around SDLC phases. Each agent has a focused context, produces structured markdown "
        "artifacts, and requires human approval before the next phase begins."
    )
    pdf.body_text(
        "Key principles:\n"
        "- One agent per SDLC phase (focused context, no bloat)\n"
        "- Structured markdown artifacts for handoff between phases\n"
        "- Human review checkpoint between every phase\n"
        "- Quick Fix agent for trivial tasks that bypass the full pipeline\n"
        "- Sub-agents within Implementation for Apex, LWC, and Flow/Config"
    )
    pdf.ln(2)
    pdf.body_text("The pipeline flow:")
    pdf.code_block(
        "User Request\n"
        "    |\n"
        "    v\n"
        "Triage: Trivial or Full SDLC?\n"
        "    |                    |\n"
        "    v                    v\n"
        "Quick Fix Agent     Phase 1: Discovery Agent\n"
        "                        | requirements.md\n"
        "                        v\n"
        "                    [Human Review]\n"
        "                        |\n"
        "                        v\n"
        "                    Phase 2: Design Agent\n"
        "                        | design.md\n"
        "                        v\n"
        "                    [Human Review]\n"
        "                        |\n"
        "                        v\n"
        "                    Phase 3: Implementation Agent\n"
        "                      |-- Apex Sub-Agent\n"
        "                      |-- LWC Sub-Agent\n"
        "                      |-- Config Sub-Agent\n"
        "                        | code + impl-summary.md\n"
        "                        v\n"
        "                    [Human Review / Code Review]\n"
        "                        |\n"
        "                        v\n"
        "                    Phase 4: Testing Agent\n"
        "                        | test-report.md\n"
        "                        v\n"
        "                    [Human QA Sign-off]\n"
        "                        |\n"
        "                        v\n"
        "                    Phase 5: Deployment Agent\n"
        "                        | deploy-runbook.md\n"
        "                        v\n"
        "                    [Human Go/No-Go]"
    )

    # === 2. Directory Structure ===
    pdf.section_heading("2. Directory Structure")
    pdf.code_block(
        ".cursor/\n"
        "|-- rules/\n"
        "|   |-- foundation/                 # Layer 1: generic SF rules\n"
        "|   |   |-- naming-conventions.md\n"
        "|   |   |-- security-baseline.md\n"
        "|   |   +-- governor-limits.md\n"
        "|   |-- phase-1-discovery.md\n"
        "|   |-- phase-2-design.md\n"
        "|   |-- phase-3-implementation.md\n"
        "|   |-- phase-4-testing.md\n"
        "|   |-- phase-5-deployment.md\n"
        "|   +-- quick-fix.md\n"
        "|\n"
        "|-- skills/\n"
        "|   |-- discovery/SKILL.md          # Phase 1 agent\n"
        "|   |-- design/SKILL.md             # Phase 2 agent\n"
        "|   |-- implementation/SKILL.md     # Phase 3 coordinator\n"
        "|   |   |-- apex/SKILL.md           # Apex sub-agent\n"
        "|   |   |-- lwc/SKILL.md            # LWC sub-agent\n"
        "|   |   +-- config/SKILL.md         # Flow/declarative\n"
        "|   |-- testing/SKILL.md            # Phase 4 agent\n"
        "|   |-- deployment/SKILL.md         # Phase 5 agent\n"
        "|   +-- quick-fix/SKILL.md          # Quick Fix agent\n"
        "|\n"
        "|-- artifacts/\n"
        "|   +-- templates/\n"
        "|       |-- requirements.md\n"
        "|       |-- design.md\n"
        "|       |-- impl-summary.md\n"
        "|       |-- test-report.md\n"
        "|       +-- deploy-runbook.md\n"
        "|\n"
        "+-- tools/\n"
        "    +-- generate-project-context.py"
    )

    # === 3. Context Budget ===
    pdf.section_heading("3. Context Budget per Agent")
    pdf.body_text(
        "Each agent loads only the rules relevant to its phase, dramatically reducing "
        "context window usage compared to the current ~320KB+ per conversation."
    )
    pdf.table(
        ["Agent", "Rules Loaded", "Est. Context"],
        [
            ["Discovery", "foundation/ + phase-1-discovery.md + project context", "~40KB"],
            ["Design", "foundation/ + phase-2-design.md + project ctx + requirements.md", "~60KB"],
            ["Implementation", "foundation/ + phase-3-impl.md + project ctx + req + design", "~80KB"],
            ["Testing", "foundation/ + phase-4-testing.md + project ctx + prior artifacts", "~60KB"],
            ["Deployment", "foundation/ + phase-5-deploy.md + project ctx + prior artifacts", "~40KB"],
            ["Quick Fix", "foundation/ + quick-fix.md + project context", "~30KB"],
        ],
    )

    # === 4. Phase 1: Discovery ===
    pdf.section_heading("4. Phase 1: Discovery Agent")
    pdf.bold_text("Purpose: ", "Understand the requirement, query the org, produce a structured requirements document.")
    pdf.ln(2)
    pdf.section_heading("Rules Loaded", level=3)
    pdf.bullet("foundation/ (naming, security, governor limits -- light reference)")
    pdf.bullet("phase-1-discovery.md (business analysis patterns, requirement gathering, MCP org queries)")
    pdf.bullet("Project context (07-active-project-context.md)")
    pdf.ln(2)
    pdf.section_heading("Input", level=3)
    pdf.body_text("User requirement (natural language, Jira ticket, or markdown file)")
    pdf.section_heading("Process", level=3)
    pdf.numbered_item(1, "Ask clarifying questions (functional, non-functional, constraints)")
    pdf.numbered_item(2, "Query org via Salesforce MCP (existing objects, fields, flows, validation rules)")
    pdf.numbered_item(3, "Identify impacted objects and existing automation")
    pdf.numbered_item(4, "Assess: is this trivially solvable with configuration? (early exit to Quick Fix)")
    pdf.ln(2)
    pdf.section_heading("Output Artifact: requirements.md", level=3)
    pdf.bullet("Feature name, description, priority")
    pdf.bullet("Functional requirements (numbered)")
    pdf.bullet("Non-functional requirements (performance, security, accessibility)")
    pdf.bullet("Impacted objects and fields (from MCP)")
    pdf.bullet("Existing automation/config found (from MCP)")
    pdf.bullet("Constraints and assumptions")
    pdf.bullet("Acceptance criteria")
    pdf.bullet("Open questions")
    pdf.ln(2)
    pdf.bold_text("Human Checkpoint: ", "Review requirements, approve or revise.")

    # === 5. Phase 2: Design ===
    pdf.section_heading("5. Phase 2: Design Agent")
    pdf.bold_text("Purpose: ", "Produce a solution design based on approved requirements.")
    pdf.ln(2)
    pdf.section_heading("Rules Loaded", level=3)
    pdf.bullet("foundation/ (shared subset)")
    pdf.bullet("phase-2-design.md (Well-Architected Framework, Configuration-First, architecture and data model patterns, integration patterns)")
    pdf.bullet("Project context")
    pdf.ln(2)
    pdf.section_heading("Input", level=3)
    pdf.body_text("Reads artifacts/{feature-name}/requirements.md")
    pdf.section_heading("Process", level=3)
    pdf.numbered_item(1, "Evaluate Configuration-First (Flow vs Apex vs Validation Rule vs Formula)")
    pdf.numbered_item(2, "If declarative: document the configuration approach")
    pdf.numbered_item(3, "If code needed: design data model, component architecture, integration points")
    pdf.numbered_item(4, "Assess against Well-Architected pillars (TRUSTED, EASY, ADAPTABLE)")
    pdf.numbered_item(5, "Identify what sub-agents are needed in Implementation (Apex? LWC? Flow?)")
    pdf.ln(2)
    pdf.section_heading("Output Artifact: design.md", level=3)
    pdf.bullet("Approach decision (declarative vs code, with rationale)")
    pdf.bullet("Data model changes (new objects/fields, ERD)")
    pdf.bullet("Component architecture (Apex classes, LWC components, Flows)")
    pdf.bullet("Integration points (if any)")
    pdf.bullet("Security considerations")
    pdf.bullet("Well-Architected assessment")
    pdf.bullet("Implementation sub-agents needed (Apex, LWC, Config)")
    pdf.bullet("Risk assessment")
    pdf.ln(2)
    pdf.bold_text("Human Checkpoint: ", "Review design, approve architecture.")

    # === 6. Phase 3: Implementation ===
    pdf.section_heading("6. Phase 3: Implementation Agent")
    pdf.bold_text("Purpose: ", "Build the solution per approved design. Coordinator dispatches to sub-agents.")
    pdf.ln(2)

    pdf.section_heading("Coordinator", level=2)
    pdf.bullet("Reads requirements.md + design.md")
    pdf.bullet("Determines which sub-agents to invoke based on the 'Implementation sub-agents needed' section from design.md")
    pdf.bullet("Dispatches work in the right order (e.g., Apex service layer before LWC that calls it)")
    pdf.bullet("Validates integration between sub-agent outputs")
    pdf.ln(2)

    pdf.section_heading("Apex Sub-Agent", level=2)
    pdf.bold_text("Rules: ", "foundation/ + phase-3-implementation.md + Apex-specific patterns (trigger framework, bulkification, service layer, CRUD/FLS)")
    pdf.bold_text("Produces: ", "Apex classes and triggers with proper naming, security, and bulkification")
    pdf.ln(2)

    pdf.section_heading("LWC Sub-Agent", level=2)
    pdf.bold_text("Rules: ", "foundation/ + phase-3-implementation.md + LWC-specific patterns (component structure, @wire, events, SLDS, accessibility)")
    pdf.bold_text("Produces: ", "LWC components with proper structure, SLDS styling, and accessibility compliance")
    pdf.ln(2)

    pdf.section_heading("Config Sub-Agent", level=2)
    pdf.bold_text("Rules: ", "foundation/ + phase-3-implementation.md + declarative patterns (Flows, Validation Rules, Formula Fields, Approval Processes)")
    pdf.bold_text("Produces: ", "Flow definitions, validation rule specs, configuration instructions")
    pdf.ln(2)

    pdf.section_heading("Output Artifact: impl-summary.md", level=3)
    pdf.bullet("Files created/modified (with paths)")
    pdf.bullet("Apex classes and their responsibilities")
    pdf.bullet("LWC components and their responsibilities")
    pdf.bullet("Flows/config changes")
    pdf.bullet("Known limitations")
    pdf.bullet("Dependencies between components")
    pdf.ln(2)
    pdf.bold_text("Human Checkpoint: ", "Code review.")

    # === 7. Phase 4: Testing ===
    pdf.section_heading("7. Phase 4: Testing Agent")
    pdf.bold_text("Purpose: ", "Produce test classes, test plans, and validate coverage.")
    pdf.ln(2)
    pdf.section_heading("Rules Loaded", level=3)
    pdf.bullet("foundation/ (shared)")
    pdf.bullet("phase-4-testing.md (testing standards, 75%+ coverage, bulk testing, mock callouts, Jest patterns, test data factories)")
    pdf.bullet("Project context")
    pdf.ln(2)
    pdf.section_heading("Input", level=3)
    pdf.body_text("Reads all prior artifacts + actual code from Phase 3")
    pdf.section_heading("Process", level=3)
    pdf.numbered_item(1, "Generate Apex test classes (bulk-safe, 200+ records, test data factory)")
    pdf.numbered_item(2, "Generate Jest tests for LWC components")
    pdf.numbered_item(3, "Create test plan (positive, negative, bulk, edge cases, security)")
    pdf.numbered_item(4, "Validate test coverage targets")
    pdf.ln(2)
    pdf.section_heading("Output Artifact: test-report.md", level=3)
    pdf.bullet("Test classes created (with paths)")
    pdf.bullet("Test plan (scenarios, expected results)")
    pdf.bullet("Coverage targets per class")
    pdf.bullet("Edge cases tested")
    pdf.bullet("Bulk test scenarios")
    pdf.bullet("Security test scenarios")
    pdf.ln(2)
    pdf.bold_text("Human Checkpoint: ", "QA sign-off.")

    # === 8. Phase 5: Deployment ===
    pdf.section_heading("8. Phase 5: Deployment Agent")
    pdf.bold_text("Purpose: ", "Prepare deployment package and runbook.")
    pdf.ln(2)
    pdf.section_heading("Rules Loaded", level=3)
    pdf.bullet("foundation/ (shared)")
    pdf.bullet("phase-5-deployment.md (CI/CD, package.xml, change sets, scratch org, validation, rollback)")
    pdf.bullet("Project context")
    pdf.ln(2)
    pdf.section_heading("Input", level=3)
    pdf.body_text("Reads all prior artifacts")
    pdf.section_heading("Output Artifact: deploy-runbook.md", level=3)
    pdf.bullet("Deployment method (source deploy, change set, package)")
    pdf.bullet("Pre-deployment steps")
    pdf.bullet("Deployment commands")
    pdf.bullet("Post-deployment validation")
    pdf.bullet("Rollback plan")
    pdf.bullet("Smoke test checklist")
    pdf.ln(2)
    pdf.bold_text("Human Checkpoint: ", "Go/no-go decision.")

    # === 9. Quick Fix ===
    pdf.section_heading("9. Quick Fix Agent")
    pdf.bold_text("Purpose: ", "Handle trivial tasks that don't warrant 5 phases.")
    pdf.ln(2)
    pdf.bold_text("Rules Loaded: ", "foundation/ + quick-fix.md (light rules covering naming, security, basic testing)")
    pdf.ln(2)
    pdf.section_heading("Scope", level=3)
    pdf.bullet("Typo fixes, simple renames")
    pdf.bullet("Single field additions")
    pdf.bullet("Simple validation rule changes")
    pdf.bullet("Label/translation updates")
    pdf.bullet("Bug fixes with obvious root cause")
    pdf.ln(2)
    pdf.bold_text("Guardrail: ", "If the Quick Fix agent determines the task is non-trivial (touches multiple objects, needs architecture decisions, has security implications), it must redirect to Phase 1: Discovery instead.")

    # === 10. Keep/Consolidate/Remove ===
    pdf.section_heading("10. What to Keep, Consolidate, or Remove")

    pdf.section_heading("Keep", level=2)
    pdf.bullet("generate-project-context.py and Layer 3.5 (project context switching) -- works well, each phase agent reads it")
    pdf.bullet("NotebookLM integration pattern (but centralize IDs into one config file)")
    pdf.bullet("Salesforce MCP integration (used primarily by Discovery and Design agents)")

    pdf.section_heading("Consolidate", level=2)
    pdf.bullet("Merge the 8 duplicated rule files (root 00-03 + layer-1-universal 00-03) into a single foundation/ set")
    pdf.bullet("Fix the SOQL limit error (150 -> 100) during consolidation")
    pdf.bullet("Merge Layer 4 methodology rules into the relevant phase rules (SPSM stages map to phases, Configuration-First goes into Design, Plan-First is now structural)")

    pdf.section_heading("Remove", level=2)
    pdf.bullet("astro/SKILL.md -- replaced by the phase pipeline structure itself (no orchestrator needed when the workflow is the orchestrator)")
    pdf.bullet("staffing-manager/SKILL.md -- team personas are no longer needed; each phase agent has its own identity")
    pdf.bullet("All 14 hardcoded persona names and warm introductions")
    pdf.bullet("Duplicated rule files")

    pdf.section_heading("Repurpose", level=2)
    pdf.body_text(
        "Existing skill content from fullstack-dev, solution-architect, lwc-developer, qa-engineer, etc. "
        "gets redistributed into the appropriate phase agent rules:\n\n"
        "- Architecture patterns -> Design agent\n"
        "- Apex patterns -> Implementation / Apex sub-agent\n"
        "- LWC patterns -> Implementation / LWC sub-agent\n"
        "- Testing patterns -> Testing agent\n"
        "- Integration patterns -> Design agent + Implementation coordinator"
    )

    # === 11. Artifact Templates ===
    pdf.section_heading("11. Artifact Templates")
    pdf.body_text(
        "Each template is a structured markdown file with clear sections. Agents fill in the sections; "
        "humans review them. The next phase agent reads the completed artifact."
    )
    pdf.ln(1)
    pdf.bold_text("Key design principle: ", "Artifacts should be self-contained -- the Design agent should be able to understand the feature from requirements.md alone, without needing the Discovery conversation history.")
    pdf.ln(2)
    pdf.body_text("Artifact summary:")
    pdf.table(
        ["Phase", "Artifact", "Key Sections"],
        [
            ["Discovery", "requirements.md", "Functional reqs, NFRs, impacted objects, acceptance criteria"],
            ["Design", "design.md", "Approach decision, data model, component arch, Well-Architected assessment"],
            ["Implementation", "impl-summary.md", "Files created, class responsibilities, component map, dependencies"],
            ["Testing", "test-report.md", "Test classes, test plan, coverage targets, edge cases"],
            ["Deployment", "deploy-runbook.md", "Deploy method, commands, rollback plan, smoke tests"],
        ],
    )

    # === 12. Migration Path ===
    pdf.section_heading("12. Migration Path")
    pdf.body_text("Recommended order of execution:")
    pdf.ln(2)
    pdf.numbered_item(1, "Consolidate rules first -- fix duplications, contradictions (SOQL limit 150->100), merge into foundation/")
    pdf.numbered_item(2, "Create artifact templates -- define the handoff contract between phases")
    pdf.numbered_item(3, "Build phase agents one at a time -- Discovery first, then Design, Implementation, Testing, Deployment")
    pdf.numbered_item(4, "Redistribute existing skill content -- move architecture patterns to Design, Apex patterns to Implementation sub-agent, testing patterns to Testing agent, etc.")
    pdf.numbered_item(5, "Build Quick Fix agent last -- simplest agent, uses consolidated foundation rules")
    pdf.numbered_item(6, "Test end-to-end -- run a real feature through all 5 phases to validate the handoff artifacts and human review checkpoints")
    pdf.ln(4)

    pdf.set_draw_color(20, 60, 120)
    pdf.line(60, pdf.get_y(), pdf.w - 60, pdf.get_y())
    pdf.ln(4)
    pdf.set_font("Helvetica", "I", 9)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(0, 5, "End of Document", align="C")

    output_path = "/Users/janantharaman/Documents/LKInsurance/Phase-Based_SDLC_Agent_Architecture.pdf"
    pdf.output(output_path)
    print(f"PDF generated successfully: {output_path}")
    print(f"Pages: {pdf.page_no()}")


if __name__ == "__main__":
    build_pdf()
