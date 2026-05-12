#!/usr/bin/env python3
"""
Generate Layer 3.5 Project Context Rule from Project Markdown Files

This script parses project documentation (markdown files) and generates
a rule file (.cursor/rules/07-active-project-context.md) that Claude Code
automatically loads via the alwaysApply: true frontmatter.

Usage:
    # Generate from project file
    python generate-project-context.py --input="PROJECT: MyProject.md"

    # Generate with custom output
    python generate-project-context.py --input="..." --output="..."

    # Deactivate project context
    python generate-project-context.py --deactivate

    # Force regeneration
    python generate-project-context.py --input="..." --force

    # Validate existing rule file
    python generate-project-context.py --validate
"""

import argparse
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Default paths
DEFAULT_OUTPUT = ".cursor/rules/07-active-project-context.md"
SCRIPT_DIR = Path(__file__).parent.parent  # .cursor/


class ProjectContextGenerator:
    """Generator for Layer 3.5 Project Context rules"""

    def __init__(self):
        self.sections = {}
        self.metadata = {}

    def parse_markdown(self, content: str) -> Dict[str, str]:
        """Parse markdown content into sections based on H1/H2 headings or special formats"""
        sections = {}
        current_section = None
        current_content = []

        lines = content.split('\n')

        for line in lines:
            # H1 heading (# Title)
            if line.startswith('# ') and not line.startswith('## '):
                if current_section:
                    sections[current_section] = '\n'.join(current_content).strip()
                current_section = line[2:].strip()
                current_content = []
            # H2 heading (## Title)
            elif line.startswith('## '):
                if current_section:
                    sections[current_section] = '\n'.join(current_content).strip()
                current_section = line[3:].strip()
                current_content = []
            # ALL CAPS section (PROJECT MANAGER MODE format)
            elif line.strip() and line.strip().isupper() and len(line.strip()) > 5:
                # Ignore decorative lines (━━━, ===, ---)
                if not all(c in '━═-─│┌┐└┘├┤┬┴┼' for c in line.strip()):
                    if current_section:
                        sections[current_section] = '\n'.join(current_content).strip()
                    current_section = line.strip()
                    current_content = []
            # "PHASE X:" pattern
            elif re.match(r'^\s*PHASE \d+:', line, re.IGNORECASE):
                if current_section:
                    sections[current_section] = '\n'.join(current_content).strip()
                current_section = line.strip()
                current_content = []
            else:
                if current_section:
                    current_content.append(line)
                elif not sections:
                    # Collect preamble before first section
                    if 'Preamble' not in sections:
                        sections['Preamble'] = line
                    else:
                        sections['Preamble'] += '\n' + line

        # Save last section
        if current_section and current_content:
            sections[current_section] = '\n'.join(current_content).strip()

        return sections

    def extract_metadata(self, sections: Dict[str, str]) -> Dict[str, str]:
        """Extract metadata from sections"""
        metadata = {
            'project_name': 'Unknown Project',
            'status': 'Active Development',
            'go_live_date': None,
            'team': [],
            'stakeholders': []
        }

        # Search all content for PROJECT: pattern
        all_content = '\n'.join(sections.values())

        # Look for "PROJECT:" pattern anywhere in content
        project_match = re.search(r'PROJECT:\s*(.+?)(?:\n|$|\()', all_content, re.IGNORECASE)
        if project_match:
            metadata['project_name'] = project_match.group(1).strip()

        # Look for status indicators
        if 'COMPLETE' in all_content or 'COMPLETED' in all_content:
            metadata['status'] = 'Completed'
        elif 'PHASE' in all_content and 'IMPLEMENTATION' in all_content:
            metadata['status'] = 'Active Development'

        # Look for team members
        for section_name, content in sections.items():
            if 'team' in section_name.lower() or 'agent' in section_name.lower():
                # Extract names from various patterns
                # Pattern 1: "- Name" or "* Name"
                names = re.findall(r'(?:^|\n)\s*[-*]\s*(.+?)(?:\n|$)', content)
                # Pattern 2: "Agent: Name"
                agent_names = re.findall(r'Agent:\s*(.+?)(?:\n|$)', content)
                if names:
                    metadata['team'].extend(names[:10])  # Limit to first 10
                if agent_names:
                    metadata['team'].extend(agent_names[:10])

        # Remove duplicates and clean
        if metadata['team']:
            metadata['team'] = list(dict.fromkeys([t.strip() for t in metadata['team'] if t.strip()]))[:5]

        # Look for stakeholders
        for section_name, content in sections.items():
            if 'stakeholder' in section_name.lower():
                names = re.findall(r'(?:^|\n)\s*[-*]\s*(.+?)(?:\n|$)', content)
                if names:
                    metadata['stakeholders'] = names[:5]

        return metadata

    def generate_frontmatter(self, input_file: str, metadata: Dict[str, str]) -> str:
        """Generate YAML frontmatter"""
        frontmatter = f"""---
alwaysApply: true
projectFile: "{input_file}"
generatedAt: "{datetime.now().isoformat()}"
version: "1.0"
layer: 3.5
type: project-context
projectName: "{metadata['project_name']}"
---
"""
        return frontmatter

    def condense_section(self, content: str, max_lines: int = 20) -> str:
        """Condense a section to key points"""
        lines = content.split('\n')

        # Keep first few lines and bullet points
        key_lines = []
        for line in lines[:max_lines]:
            stripped = line.strip()
            if stripped:
                # Keep headings, bullet points, and numbered lists
                if (stripped.startswith('#') or
                    stripped.startswith('-') or
                    stripped.startswith('*') or
                    re.match(r'^\d+\.', stripped)):
                    key_lines.append(line)
                # Keep first non-empty line
                elif not key_lines:
                    key_lines.append(line)

        return '\n'.join(key_lines) if key_lines else content[:500]

    def generate_rule_content(self, sections: Dict[str, str], metadata: Dict[str, str]) -> str:
        """Generate the rule markdown content"""
        content = f"""
# Active Project Context (Layer 3.5)

## Project Overview

- **Project**: {metadata['project_name']}
- **Status**: {metadata['status']}
"""

        if metadata.get('go_live_date'):
            content += f"- **Go-Live**: {metadata['go_live_date']}\n"

        if metadata.get('team'):
            content += f"- **Team**: {', '.join(metadata['team'][:5])}\n"

        content += "\n"

        # Add key sections (condensed)
        priority_sections = [
            'Requirements', 'Architecture', 'Design', 'Technical',
            'Security', 'Integration', 'API', 'Data Model',
            'Sprint', 'Current', 'Stakeholder'
        ]

        for priority in priority_sections:
            for section_name, section_content in sections.items():
                if priority.lower() in section_name.lower():
                    content += f"## {section_name}\n\n"
                    condensed = self.condense_section(section_content, max_lines=15)
                    content += f"{condensed}\n\n"
                    break

        # Add footer
        content += """---

## When This Context Applies

This project context is **ALWAYS ACTIVE** when this rule file exists.

To deactivate project context (switch to generic development mode):
```bash
python .cursor/tools/generate-project-context.py --deactivate
```

To switch projects:
```bash
python .cursor/tools/generate-project-context.py --input="path/to/other/PROJECT.md"
```

**See also**:
- Layer 1: Foundation Rules (00-06.md) for universal Salesforce knowledge
- Layer 4: SPSM Framework for project methodology
- Layer 4: Well-Architected Framework for architectural principles
"""

        return content

    def generate(self, input_file: str, output_file: str, force: bool = False) -> bool:
        """Generate project context rule from input file"""
        # Check input file exists
        input_path = Path(input_file)
        if not input_path.exists():
            print(f"❌ Error: Input file not found: {input_file}")
            return False

        # Check output file exists (unless force)
        output_path = Path(output_file)
        if output_path.exists() and not force:
            print(f"⚠️  Output file already exists: {output_file}")
            print(f"   Use --force to overwrite")
            return False

        print(f"📄 Reading project file: {input_file}")

        try:
            # Read input file
            with open(input_path, 'r', encoding='utf-8') as f:
                content = f.read()

            file_size = len(content)
            print(f"✓ Parsed project file ({file_size / 1024:.1f} KB)")

            # Parse markdown
            sections = self.parse_markdown(content)
            print(f"✓ Extracted {len(sections)} sections")

            # Extract metadata
            metadata = self.extract_metadata(sections)
            print(f"✓ Detected project: {metadata['project_name']}")

            # Generate frontmatter
            frontmatter = self.generate_frontmatter(input_file, metadata)

            # Generate rule content
            rule_content = self.generate_rule_content(sections, metadata)

            # Write output file
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(frontmatter)
                f.write(rule_content)

            output_size = len(frontmatter) + len(rule_content)
            print(f"✓ Generated rule file: {output_file} ({output_size / 1024:.1f} KB)")
            print(f"✓ Frontmatter: alwaysApply=true, projectFile set")
            print(f"✅ Project context active")

            return True

        except Exception as e:
            print(f"❌ Error generating rule: {e}")
            import traceback
            traceback.print_exc()
            return False

    def deactivate(self, output_file: str) -> bool:
        """Deactivate project context by removing rule file"""
        output_path = Path(output_file)

        if not output_path.exists():
            print(f"ℹ️  No project context active (file not found: {output_file})")
            return True

        try:
            output_path.unlink()
            print(f"✓ Removed: {output_file}")
            print(f"✓ Project context deactivated")
            print(f"✓ Generic development mode active")
            return True
        except Exception as e:
            print(f"❌ Error removing file: {e}")
            return False

    def validate(self, rule_file: str) -> bool:
        """Validate existing rule file"""
        rule_path = Path(rule_file)

        if not rule_path.exists():
            print(f"❌ Rule file not found: {rule_file}")
            return False

        print(f"🔍 Validating: {rule_file}")

        try:
            with open(rule_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Check frontmatter
            if not content.startswith('---'):
                print(f"❌ Missing frontmatter")
                return False

            # Extract frontmatter
            parts = content.split('---', 2)
            if len(parts) < 3:
                print(f"❌ Invalid frontmatter format")
                return False

            frontmatter = parts[1]

            # Check required fields
            required_fields = ['alwaysApply: true', 'projectFile:', 'layer: 3.5']
            for field in required_fields:
                if field not in frontmatter:
                    print(f"❌ Missing required field: {field}")
                    return False

            print(f"✅ Valid rule file")
            print(f"   Size: {len(content) / 1024:.1f} KB")

            return True

        except Exception as e:
            print(f"❌ Error validating file: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description='Generate Layer 3.5 Project Context Rule',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate from project file
  python generate-project-context.py --input="PROJECT: MyProject.md"

  # Deactivate project context
  python generate-project-context.py --deactivate

  # Force regeneration
  python generate-project-context.py --input="..." --force

  # Validate existing rule
  python generate-project-context.py --validate
        """
    )

    parser.add_argument('--input', type=str,
                        help='Input project markdown file')
    parser.add_argument('--output', type=str, default=DEFAULT_OUTPUT,
                        help=f'Output rule file (default: {DEFAULT_OUTPUT})')
    parser.add_argument('--force', action='store_true',
                        help='Force overwrite existing output file')
    parser.add_argument('--deactivate', action='store_true',
                        help='Deactivate project context (remove rule file)')
    parser.add_argument('--validate', action='store_true',
                        help='Validate existing rule file')

    args = parser.parse_args()

    generator = ProjectContextGenerator()

    # Handle deactivate
    if args.deactivate:
        success = generator.deactivate(args.output)
        sys.exit(0 if success else 1)

    # Handle validate
    if args.validate:
        success = generator.validate(args.output)
        sys.exit(0 if success else 1)

    # Handle generate
    if not args.input:
        parser.print_help()
        print("\n❌ Error: --input required (or use --deactivate/--validate)")
        sys.exit(1)

    success = generator.generate(args.input, args.output, args.force)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
