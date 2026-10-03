# Repair or replace — decide it by running it, never by estimating it

Read this at stage 3 of **compound-v:get-shit-done** (**compound-v:get-shit-done-3-build**), when you are about to put a third patch onto the
same shape, or when a slice's third failed close says *the shape is wrong*. It lives outside the
skill because it is needed at one moment and the skill is read at every moment — and because the
done-gate it used to sit above was falling past the compaction line, which is the one part of that
skill that must survive.

`blocked` is what you mark when the replacement failed too, not instead of trying it.

The third patch onto the same shape is a decision being made by default. Make the decision deliberately instead, and make it on evidence: **build the replacement in a throwaway worktree and run the existing check against both** — *"if one experiment fails, I throw away that worktree and nothing is lost in main."* The under-selection is measured: on held-out checkpoints, two of three frontier models met rising requirements by making functions bigger *"rather than moving things around"*, one going from 4.6% duplicated lines to 16.8%. *Why* is less settled — scoring pairs the fix with `PASS_TO_PASS` and *"there is no penalty for eroding codebase maintainability"*, which would reward minimal additive change, but that is a reasonable read rather than a demonstrated cause. Rely on the behaviour, not the explanation, which is why the answer is a run and not an argument.

**Say what the run decides before you start it:** replace if the rebuild passes a check the incumbent fails, or passes the same one with the next change landing in one place instead of many. Otherwise repair — and a rebuild that merely *feels* cleaner while both arms pass identically is the incumbent winning. Decide the criterion after the run and the arm you enjoyed building wins.

Three conditions separate this from licence:

- **The check pre-dates the replacement, and you know what it cannot see.** The whole-runtime port everyone cites named its substrate as load-bearing — *"he defined a test suite … it's very, very well tested … So it's easy to know if you did the right thing."* Grading a rebuild with tests the rebuild wrote is the reward-tampering rule above in a new hat. But a check covers only behaviour someone wrote down, and what a rewrite loses is the behaviour nobody did — the edge cases the old code earned in production. Recover that contract first (**compound-v:extracting-specs**); a green bake-off over a thin suite is a confident way to ship a regression.
- **Name which cost you are paying.** Producing a replacement collapsed: that port ran **eleven days** on one steered prompt (a second telling says a week) against a human estimate of *"definitely over a year"*. Judging did not, and that is the cost to plan around — an agent loop reported a renderer at 88ms → 1.5ms, which reads as success until you learn the hand-written version was *"roughly 75x better"* again. Nothing touched the third cost: migrating accumulated data, or a published surface whose migration is *other people's* work. So run the seam test — *if I am wrong, can I fix this by rewriting code, or only by migrating data?* Code-only is machinery, and machinery was always meant to be replaced.
- **The rows move with it, and the rebuilder does not rewrite them.** The replaced thing's open rows are `moved` with successors named, never `void`; its passed rows go red and are re-walked. Each successor inherits its predecessor's `does` — one promising less is editing a check by another route.


Keep the scale honest: whole-product one-shotting is the *other* documented failure and it is first on the list. This is a move inside one slice, not a licence to restart the project.
