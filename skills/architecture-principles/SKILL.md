---
name: architecture-principles
description: "Clean architecture layering and SOLID principles for structuring or reviewing code: the Dependency Rule, Entities/Use Cases/Interface Adapters/Frameworks layers, and SRP/OCP/LSP/ISP/DIP. Use when designing where new logic belongs, checking a class or interface against SOLID, or judging whether a change respects layer boundaries."
---

# Architecture Principles

Shared reference for [clean-architecture.md](./clean-architecture.md) (layers, the Dependency Rule, Use Case Output) and [solid.md](./solid.md) (SRP, OCP, LSP, ISP, DIP). It is a reference to consult, not a session to run: read the two files for the vocabulary and rules, then apply them to the code at hand.

Use it to:
- Decide which layer new logic belongs in and keep dependencies pointing inward per the Dependency Rule.
- Check a class or interface against SOLID before moving on to the next piece of work.
- Judge whether an existing change respects layer boundaries and SOLID, as part of a review or quality gate.
