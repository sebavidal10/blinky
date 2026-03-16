---
name: Code Precision and Syntax Guard
description: Guidelines to prevent syntax errors like extraneous braces or missing imports during code modifications.
---

# Code Precision and Syntax Guard

This skill ensures that every code modification maintains the structural integrity of the file and avoids common syntax errors, particularly when using `multi_replace_file_content` or `replace_file_content`.

## Precision Rules

1. **Brace Integrity**: 
   - Before applying an edit, always count opening and closing braces in the `TargetContent` and ensure the `ReplacementContent` maintains a valid balance.
   - Avoid including the final brace of a method if you are only adding lines *inside* the method, unless you are absolutely sure of the context.
   - **Check for "Double Closure"**: Ensure your edit doesn't accidentally include a closing brace that is already present in the lines immediately following the `TargetContent`.

2. **Context Awareness**:
   - Always view at least 5-10 lines *before* and *after* the section you intend to edit to understand the nesting level.
   - If the file has a lot of similar-looking closures, include more surrounding context in `TargetContent` to make it unique and identifiable.

3. **Incremental Verification**:
   - After a significant edit, use `view_file` to inspect the modified area and confirm that there are no "dangling" braces or syntax errors.
   - If a file fails to compile (or shows syntax errors), immediately inspect the lines reported in the error message and the surrounding scope.

4. **Swift Specifics**:
   - Be wary of trailing closures and their braces.
   - Ensure `@objc` methods and protocols are correctly closed.

4. **Mandatory Syntax Verification**:
   - After *every* edit to a `.swift` file, you MUST perform a visual check of the surrounding scope to ensure all braces are balanced.
   - If in doubt, use `run_command` with `swiftc -parse <file_path>` to catch structural errors, even if it reports missing module errors (it will still report extraneous braces first).

## Error Prevention Workflow

1. **Plan**: Identify the exact lines.
2. **Double-Check**: Compare the last line of your `ReplacementContent` with what will follow in the file.
3. **Apply**: Execute the tool call.
4. **Verify**: View the file to ensure the closing braces match the indentation and scope.
