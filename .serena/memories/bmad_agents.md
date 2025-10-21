# BMAD Agent System

This project uses a BMAD (Business, Management, and Development) agent system for structured development workflow.

## Available Agents

### @po (Product Owner)
- **Location**: `.claude/BMad/agents/po.md`
- **Capabilities**: 
  - Document sharding
  - Validation
  - Process oversight
  - Epic management

### @sm (Scrum Master)
- **Location**: `.claude/BMad/agents/sm.md`
- **Capabilities**: 
  - Story creation from epics
  - Sprint planning
  - Task breakdown

### @dev (Developer)
- **Location**: `.claude/BMad/agents/dev.md`
- **Capabilities**: 
  - Code implementation
  - Feature development
  - Bug fixes

### @qa (QA Specialist)
- **Location**: `.claude/BMad/agents/qa.md`
- **Capabilities**: 
  - Code review
  - Testing
  - Quality assurance

## Usage

When the user references an agent (e.g., "@po", "@sm", "@dev", "@qa"), you should:
1. Read the corresponding agent file from `.claude/BMad/agents/[agent].md`
2. Embody that agent's persona and capabilities completely
3. Follow the agent's specific instructions and workflows

## Documentation Structure

The project follows a hierarchical documentation structure:
- **Epics**: High-level feature sets (in `docs/epics/`)
- **Stories**: Individual tasks derived from epics (in `docs/stories/`)
- **Implementation Reports**: Completion documentation
- **QA Reports**: Testing and validation documentation

## Workflow

The BMAD system enforces a structured workflow:
1. **PO** defines and manages epics
2. **SM** breaks epics into stories
3. **Dev** implements stories
4. **QA** reviews and validates implementations

This system is designed for AI-first development, ensuring clear documentation and traceability throughout the development process.
