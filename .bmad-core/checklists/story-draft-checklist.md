# Story Draft Quality Checklist

Use this checklist to validate that a story is complete and ready for development.

## Story Metadata

- [ ] Story has unique ID (STORY-{epic}.{number})
- [ ] Story has clear, descriptive title
- [ ] Epic reference is correct
- [ ] Priority assigned (P0-P3)
- [ ] Story points estimated (1,2,3,5,8)
- [ ] Sprint day assigned (if applicable)
- [ ] Created date set

## Story Content

### Description Section
- [ ] User story follows "As a... I need... So that..." format
- [ ] User type/role is clearly identified
- [ ] Capability/feature is specific and actionable
- [ ] Business value is clearly stated
- [ ] Additional context provides sufficient background

### Acceptance Criteria
- [ ] At least 3 acceptance criteria defined
- [ ] Criteria are specific and testable
- [ ] Criteria are measurable (not vague)
- [ ] Criteria cover main functionality
- [ ] Criteria cover edge cases (if applicable)
- [ ] All criteria use checkbox format (- [ ])

### Technical Tasks
- [ ] Tasks are broken down into logical steps
- [ ] Tasks are specific and actionable
- [ ] Tasks include code/config details where needed
- [ ] Tasks reference specific files/locations
- [ ] Tasks are in logical order
- [ ] Each task is independently completable

## Technical Specifications

### Files Section
- [ ] All files to create are listed
- [ ] All files to modify are listed
- [ ] File paths are accurate
- [ ] File actions are marked (create/modify)

### Code Examples
- [ ] Relevant code snippets included (if applicable)
- [ ] Code examples are from architecture docs
- [ ] Code examples follow Swift 6 standards
- [ ] Code examples are properly formatted

### Dependencies
- [ ] Required dependencies listed (stories, setup, etc.)
- [ ] Blocking relationships identified
- [ ] External dependencies documented
- [ ] Dependencies are realistic and accurate

## Testing & Validation

### Test Procedure
- [ ] Step-by-step testing instructions provided
- [ ] Verification steps are clear
- [ ] Expected outcomes defined
- [ ] Test procedure is executable by QA

### Success Criteria
- [ ] Build verification included
- [ ] Runtime verification included
- [ ] Feature-specific verification included
- [ ] Performance criteria defined (if applicable)

## References

- [ ] Architecture docs referenced
- [ ] PRD sections linked
- [ ] Implementation guides referenced (SwiftData, Firebase, etc.)
- [ ] Related stories linked (if applicable)

## Notes & Considerations

### Implementation Notes
- [ ] Important notes for developer included
- [ ] Gotchas or tricky parts highlighted
- [ ] Best practices referenced

### Edge Cases
- [ ] Edge cases identified
- [ ] Edge case handling specified

### Non-Functional Requirements
- [ ] Performance considerations addressed
- [ ] Security considerations addressed
- [ ] Offline behavior specified (if applicable)

## AI-First Compliance

- [ ] Story is atomic (single focused feature)
- [ ] Story is independently implementable
- [ ] Story language is clear and unambiguous
- [ ] Story references source documentation (not assumptions)
- [ ] Story avoids vague terms ("better," "improved," etc.)
- [ ] Story is implementable by "dumb AI agent"

## Swift 6 & iOS 17+ Compliance

- [ ] Swift concurrency patterns specified (async/await)
- [ ] SwiftUI patterns specified (if UI work)
- [ ] SwiftData patterns specified (if data work)
- [ ] iOS 17+ features utilized appropriately
- [ ] No deprecated APIs referenced

## Firebase Integration Compliance

- [ ] Firebase service usage specified (Auth, Firestore, etc.)
- [ ] Offline-first approach considered
- [ ] Security rules mentioned (if applicable)
- [ ] Error handling specified

## Ready for Development?

**Final Checks:**

- [ ] Story can be implemented in single sprint day or less
- [ ] Story delivers tangible value
- [ ] Story has clear done criteria
- [ ] Story is understandable without additional explanation
- [ ] Developer can start immediately without questions

**Checklist Status:**

- **Total Items:** {count}
- **Completed:** {count}
- **Percentage:** {%}

**Recommendation:**

- [ ] ✅ **APPROVED** - Story ready for development
- [ ] ⚠️ **NEEDS REVISION** - Address issues below
- [ ] ❌ **BLOCKED** - Cannot proceed (see blockers)

**Issues to Address:**

{List any items that failed checklist}

---

**Reviewed by:** {Agent/Person}
**Review date:** {YYYY-MM-DD}
