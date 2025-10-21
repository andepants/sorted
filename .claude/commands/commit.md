# Commit Command

This command will:
1. Run SwiftLint to check for code quality issues
2. Stage all files for commit
3. Create a commit with a descriptive summary

## Instructions

Please execute the following steps:

1. First, check if SwiftLint is installed. If not, inform the user they need to install it with `brew install swiftlint`

2. Run SwiftLint on the project:
   - Execute `swiftlint lint --strict` in the project directory (this will use the .swiftlint.yml configuration)
   - If there are any errors or warnings, display them to the user
   - If there are errors (not just warnings), ask the user if they want to proceed or fix them first
   - Optionally offer to run `swiftlint --fix` to automatically fix some issues

3. Stage all changes:
   - Run `git add .`
   - Show the user what files will be committed with `git status`

4. Create a commit:
   - Analyze the staged changes with `git diff --staged`
   - Generate a clear, concise commit message that:
     - Starts with a conventional commit type (feat, fix, refactor, docs, etc.)
     - Summarizes the changes in present tense
     - Includes relevant details in the body if needed
   - Create the commit with the generated message
   - Include the Claude Code attribution footer:
     ```
     🤖 Generated with [Claude Code](https://claude.com/claude-code)

     Co-Authored-By: Claude <noreply@anthropic.com>
     ```

Throughout this process, keep the user informed of each step and any issues encountered.
