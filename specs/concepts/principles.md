# Core Principles

You are not managing backwards compatibility or migration. You should be designing for the optimal design based on the information you've accrued.

## The Development Workflow: Research, Workbench, Prototype

We prioritize reasoning and validation over rapid, unthinking implementation. Our process is a loop of observation, reasoning, and testing.

### 1. Research (Observation)
*   **Scope**: `specs/research`
*   **Method**: Observe prior art and external systems. We collect observations without prescription.

### 2. Workbenches (Reasoning)
*   **Scope**: Evaluate candidates for a specific technical question.
*   **Method**: Workbens reason through options. Once a conclusion is reached, the decision is immutable.

### 3. Prototypes (Validation)
*   **Scope**: Throwaway code.
*   **Method**: Test specific hypotheses generated in Workbenches. The point of prototyping is to find where the model bends—and to bend the model where appropriate.

---

## Engineering Artifacts

*   **Decisions**: Numbered commitments accompanied by rationale. They are revisable when evidence warrants.
*   **Specs**: The canonical, production-ready definitions of the things we are building. The high source of truth.
*   **Concepts**: Cross-cutting ideas and abstractions that span multiple artifacts.
*   **Reference Code**: Production-quality, implementation-standard code.

---

## Fundamental Mindsets

### Zero-Legacy Design
We do not design for consumers, migration burdens, or backward compatibility constraints. The goal is to arrive at a proven, cohesive API and design for the feature before shipping.

### First-Principles Reasoning
Do not default to "the current model requires X." In Workbenches, ask: *"What model would we design if we had known about this requirement from the start?"*

### Accumulate, Don't Discard
Build on accumulated work. However, when tension surfaces between an existing decision and a more elegant solution, name the tension explicitly and evaluate it honestly. Changing a decision is expected; ignoring evidence to preserve one is not.

### Stress Test with Capability
Each new feature is an opportunity to validate or improve the architecture. Use real-world capabilities to test the limits of the model.

---

## Simple over Easy
Inspired by Rich Hickey's "Simple Made Easy."

* **Simple vs. Easy**: 
    * **Simple**: An objective property of the artifact; it is uncomplicated, having one braid and one role.
    * **Easy**: A subjective property of the experience; it is near at hand and familiar.
* **The Priority**: Prioritize simplicity (the integrity of the artifact) over ease (the convenience of constructing it).
* **Avoid Complecting**: Do not interleave concerns that should be separate. 
* **Complexity is not Minimalism**: Simple does not equal minimal. A simple component can have a rich API if it serves exactly one role.

## Architectural Pillars

### Composition
Build complex behaviors by combining simple, discrete parts rather than creating monolithic structures.

### Separation of Concerns
Each layer must maintain one role and one authority. Avoid co-owned state.
* **Input State**: Owned by the browser.
* **Interaction State**: Derived from the interaction surface.
* **Content State**: Owned by the host.

## Design & Development Principles

### Dieter Rams' Principles (Adapted)
Adapted from industrial design to complement technical principles with a user-centered lens.

1. **Good design is innovative**: Technological development offers constant new opportunities.
2. **Good design makes a product useful**: It must satisfy functional, psychological, and aesthetic criteria.
3. **Good design is aesthetic**: The aesthetic quality is integral to usefulness and well-being.
4. **Good design makes a product understandable**: It clarifies structure and effectively "speaks" to the user.
5. **Good design is unobtrusive**: Products are tools; their design should be neutral to allow for user self-expression.
6. **Good design is honest**: It does not make a product appear more valuable or powerful than it truly is.
7. **Good design is long-lasting**: It avoids being fashionable and resists becoming antiquated.
8. **Good design is thorough down to the last detail**: Nothing is left to chance; accuracy shows respect for the user.
9. **Good design is sustainable**.
10. **Good design concentrates on the essential**: Products are not burdened with non-essentials.

### Validate Before Committing
Specs and decisions represent the best reasoning at the time, but reasoning alone cannot validate behavioral changes. **Prototype first, then promote to the reference implementation.**

### Naming Honesty
Name properties for what the value *is*, not for the action that changes it.
* Collapsing distinct concepts into a single name is complecting. Two terms, each with one meaning, is more frugal than one overloaded term.

### Frugality
Be frugal with concepts; every new term increases cognitive load.
* **Prefer Implicit Context**: Use context rather than explicit prefixes when the relationship is unambiguous.
* **Avoid Premature Abstraction**: Do not add abstractions until they are strictly required by the current problem.