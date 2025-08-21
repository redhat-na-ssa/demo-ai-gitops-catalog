# Demos - Recommended Practices

Below are recommended practices or references.

## Building Demos

### Common cli tools across platforms

- `git`
- `bash`
- `oc` / `kubectl`
- `python` >= `3.9`
    - `ansible`

### Considerations

- ALWAYS **start** with a `README.md`
    - One sentence is ok
    - Example
        - Title: Weather Toaster
        - Body: I want to build a toaster that controls the weather
    - ALWAYS commit to `git` - *except when it comes to secrets*
    - Use a public `git` location - We can always rewrite (git) history to make it look perfect
- One click solutions
    - `scripts/bootstrap.sh`
    - `oc apply -k`
    - Offer a solution that takes less than 5 minutes of user interaction to complete (your automation can take longer)
    - Exception: When you are building training into your demo
- Make friends / Collaborate - Have ~~strange people~~ others test your work
    - Regular peer reviews (short and frequent)
    - 3 days max between peer review
- Modular design - Build for reuse
    - *How can I make this easy for someone to reuse my work?*
- Goal: avoid *"it worked on my machine..."*

### Architecture

- Assume minimum privilege for the user / demo
    - User may only have access to `namespace` not `cluster-admin`
    - Use appropriate role bindings, avoid `admin`
- Use the minimum number of tools and dependencies
- Scripting
    - Avoid complex functions (`bash`, `python`, `Makefile`)
    - Transparency - attempt to show commands for manual operations
    - Use `functions()` for reusability
    - *Can I cut and paste?* - use sparingly
