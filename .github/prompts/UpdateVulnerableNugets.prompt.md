---
mode: agent
---
# NuGet Package Update and Fix Agent Instructions

## Objective
Identify vulnerable and outdated NuGet packages in a .NET solution, update them, fix any breaking changes, and ensure all tests pass.

## Step-by-Step Process

### Phase 1: Discovery
1. **Locate the solution file**
   - Find the `.sln` file in the repository root
   - Identify all `.csproj` files in the solution

2. **Check for vulnerable packages (PRIORITY)**
   - Run `dotnet list package --vulnerable` for each project
   - Document all packages with known security vulnerabilities
   - Note severity levels (Critical, High, Moderate, Low)
   - Note CVE identifiers if available

3. **Check for outdated packages**
   - Run `dotnet list package --outdated` for each project
   - Document all packages that have newer versions available
   - Note current versions and available versions

4. **Prioritize updates**
   - **Critical/High severity vulnerabilities** - Update immediately, highest priority
   - **Moderate/Low severity vulnerabilities** - Update next
   - **Outdated packages without vulnerabilities** - Update after security fixes

### Phase 2: Update Packages
5. **Create a backup**
   - Create a new git branch for the update work
   - Commit current state before making changes

6. **Update vulnerable packages FIRST**
   - Start with Critical and High severity vulnerabilities
   - Run `dotnet add package <PackageName>` to update to latest secure version
   - Update one vulnerable package at a time
   - Test build after each critical vulnerability fix

7. **Update remaining outdated packages**
   - Update moderate/low vulnerability packages
   - Then update non-vulnerable outdated packages
   - Group compatible minor updates together
   - Update major version changes individually

### Phase 3: Build and Fix
8. **Attempt to build the solution**
   - Run `dotnet build` or `dotnet build <solution>.sln`
   - Capture all build errors and warnings

9. **If build fails, analyze and fix**
   - Identify breaking API changes from error messages
   - Check package release notes and migration guides for each updated package
   - Common issues to look for:
     - Renamed methods or properties
     - Changed method signatures
     - Removed deprecated APIs
     - Namespace changes
     - Configuration changes
     - Security-related API changes (authentication, authorization, encryption)
   - Fix each compilation error:
     - Update method calls to match new signatures
     - Replace deprecated APIs with recommended alternatives
     - Add or update using statements for namespace changes
     - Update dependency injection registrations if needed
     - Update security configurations

10. **Repeat build until successful**
    - After each fix, rebuild
    - Continue until `dotnet build` completes without errors

### Phase 4: Test and Validate
11. **Run all tests**
    - Execute `dotnet test` to run the entire test suite
    - Note any failing tests

12. **Fix failing tests**
    - For each failing test:
      - Analyze the failure message and stack trace
      - Determine if failure is due to:
        - Changed behavior in updated packages
        - Updated test framework APIs
        - Security-related changes (stricter validation, etc.)
        - Timing or async issues
        - Mock/stub setup issues
      - Update test code to work with new package versions:
        - Update assertions if behavior changed legitimately
        - Fix test setup code for new APIs
        - Update mock expectations
        - Adjust test data if needed
        - Update security test configurations

13. **Verify all tests pass**
    - Run `dotnet test` again
    - Ensure 100% test pass rate
    - Check that test coverage hasn't decreased significantly

### Phase 5: Verification and Documentation
14. **Re-check for vulnerabilities**
    - Run `dotnet list package --vulnerable` again
    - Confirm no vulnerable packages remain
    - If vulnerabilities persist, document why (no fix available, etc.)

15. **Document changes**
    - Create a summary of:
      - **Security vulnerabilities fixed** (with CVE numbers and severity)
      - Which packages were updated (old version → new version)
      - Breaking changes encountered and how they were fixed
      - Any test modifications made
    - Update CHANGELOG.md if it exists
    - Highlight security improvements

16. **Final validation**
    - Run `dotnet clean` followed by `dotnet build`
    - Run full test suite one more time
    - Verify no vulnerable packages with `dotnet list package --vulnerable`
    - Check for any new warnings introduced

17. **Submit work**
    - Commit all changes with clear commit messages
    - Create a pull request with detailed description
    - **Clearly mark security-related updates in PR title/description**
    - Include migration notes for other developers

## Error Handling Rules
- **Never roll back security vulnerability fixes** - seek alternative solutions
- If a security update causes unfixable breaking changes, document and escalate
- If non-security package update causes issues, consider rolling back
- If tests cannot be fixed, document why and seek human review
- If build fails after multiple attempts, bisect updates to find problematic package
- Always maintain a working state before moving to next package group

## Success Criteria
✅ **Zero vulnerable packages remaining** (CRITICAL)  
✅ All outdated packages updated to latest compatible versions  
✅ Solution builds without errors  
✅ All tests pass  
✅ No new warnings introduced  
✅ Security improvements documented  

## Tools and Commands Reference
- `dotnet list package --vulnerable` - **List packages with security vulnerabilities (PRIORITY)**
- `dotnet list package --outdated` - List outdated packages
- `dotnet add package <Name>` - Update a package
- `dotnet build` - Build the solution
- `dotnet test` - Run all tests
- `dotnet clean` - Clean build artifacts

## Important Notes
- **Security vulnerabilities must be addressed**, even if they cause breaking changes
- Document any vulnerabilities that cannot be fixed immediately
- Prioritize keeping the application secure over maintaining old APIs