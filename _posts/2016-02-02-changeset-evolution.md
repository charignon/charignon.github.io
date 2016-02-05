---
layout: post
title: Changeset Evolution
---
## Changeset What?

[Mercurial](https://mercurial-scm.com) is a distributed version control system, similar to [git](https://git-scm.com/).
If you have not tried it yet, you really should!


I work on Mercurial, and as you know already, I love to automate everything.
If you use git and mercurial today, you know that source control is not trivial, 
 workflows could be easier and require less manual intervention and dark magic. 


**[Changeset evolution](https://www.mercurial-scm.org/wiki/ChangesetEvolution) is a proposal to make 
source-control less error-prone, more forgiving and flexible.**
I will use **changeset evolution** and **evolve** interchangeably.
Pierre-Yves David created Changeset Evolution and you can see [his talk
at FOSDEM 2013](https://air.mozilla.org/changesets-evolution-with-mercurial/)


## The history of commits does not exist

Let's start with an example. Assume that a user committed **b** on top of **a**: 

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend1.dot.svg" />
<figcaption>Starting point</figcaption>
</figure>

After making some changes, the user runs `hg commit --amend` (like git `commit --amend`) and decides to call the new commit **b'**:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="After running the amend command" src ="/assets/evolve/amend2.dot.svg" />
<figcaption>After amend</figcaption>
</figure>

Under the cover, the amend command creates a new commit but the old revision is still there but hidden:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Under the cover" src ="/assets/evolve/amend3.dot.svg" />
<figcaption>b didn't disappear yet, it is hidden</figcaption>
</figure>


For the user, **b' is a newer version of b**.
Even though, the intent of amending is clear, **no information about this intent is recorded in the source control system!**

If the user wants to access, let's say a week from now, what **b** was before the amend, he or she will have to dig through the **revlog** to find the hash of **b**.

What if we could record that b' is the successor of b?

## Defining the commit history with obsolescence markers

**Changeset evolution** introduces the concept of **obsolescence markers** to represent that a revision is the **successor** of another revision.
I will represent the **obsolescence markers** with dotted lines in the following graphs.
In the example above after running `hg commit --amend` we would have:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend4.dot.svg" />
<figcaption>Recording that b' is the <b>successor</b> of b with an obsolescence marker. b is the <b>precursor</b> of b'</figcaption>
</figure>

And after running `hg commit --amend` again:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend5.dot.svg" />
<figcaption>Two amends: b" is the <b>successor</b> of b' and b' is the <b>successor</b> of b</figcaption>
</figure>

All this is happening **under the hood**, and the user does not see any difference in the UI.
It is just some extra information that is recorded that can be used by commands as we will see in the next section.


## Simplify rebases, go back in time and don't make mistakes

Let's see how we can **seamlessly use the obsolescence markers** to simplify the life of the user through three examples.

### 1. Easily accessing a precursor:

Consider the situation discussed above:
<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend4.dot.svg" />
<figcaption>After <b>hg commit --amend</b></figcaption>
</figure>

We can give the user some **commands to access precursors of revisions to compare them or manipulate them**.
After running the amend, you can easily:
- Go back to the previous version (without using the revlog)
- Figure out what changes the amend introduced.

### 2. Rebasing with fewer conflicts:

It is common to have a testing/continuous integration system run all the tests on a revision before pushing it
to a repository. Let's assume that you are working on a feature and committed **b** and **c** locally.

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/push1.dot.svg" />
<figcaption>Before pushing b to the server on top of d</figcaption>
</figure>

Satisfied with **b**, you send it to the CI system that pushes it onto `remote/master` on the server, when you pull, you will have:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/push2.dot.svg" />
<figcaption>Pushing a commit can also add a marker</figcaption>
</figure>

If you pull one hour later (assuming other people are very productive :D) you will have something like:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/push3.dot.svg" />
<figcaption>When rebasing the stack, the first commit can be skipped</figcaption>
</figure>

And if you try to rebase your stack (b and c) on top of master, you will potentially have conflicts applying b because of the work of another developer.
This could happen if this other developer changed the same files you changed in **b**.
But in that case, you know that the person resolved the conflicts once already when applying their work on top of **newb**.
**The user should have to resolve conflicts in that case and obsolescence markers can help resolving this**.
What if on pull the server could tell you that **newb** is the new version of *b*:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/push4.dot.svg" />
<figcaption>When rebasing the stack, the first commit can be omitted</figcaption>
</figure>

This way when you rebase the stack, only **d** gets rebased, **b is skipped, and you cannot get conflicts from the content in b**.

### 3. Working with other people

Let's assume that you start from this simple state:
<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend1.dot.svg" />
<figcaption>Starting point</figcaption>
</figure>

And you and your friend work on making changes to b, you create a new change **b'** and your friend creates a new version of b called: **b''**

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend4.dot.svg" />
<figcaption>The first developer rewrote b</figcaption>
</figure>

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend6.dot.svg" />
<figcaption>The second developer rewrote b as well</figcaption>
</figure>

Then you decide to put your work together:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend7.dot.svg" />
<figcaption>b has two successors, <b>b'</b> and <b>b''</b> are called divergent</figcaption>
</figure>

In **git** or **vanilla (no extension) mercurial**, you would have to figure out that **b'** and **b''** are two new versions of **b** and merge them.
**Changeset evolution** detects that situation, marks **b'** and **b''** as being divergent.
It then suggests **automatic resolution with a merge and preserves history.**


<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/amend8.dot.svg" />
<figcaption>Everything gets resolved intelligently</figcaption>
</figure>

The graph might seem overcomplicated, but once again, most things are happening **under the hood** and the UI impact is minimal.
These examples **show** the power of changeset evolution, to provide an **automatic resolution** of typical source control issues.
But, the true power of **changeset evolution** is the flexibility that it gives when working with stacks of commits.

## A more flexible workflow with stacks

**Changeset evolution** defines the concept of an **unstable** revision, a revision based on an obsolete revision.
From the previous section:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/push4.dot.svg" />
<figcaption>c is unstable because it is based on b and b has as a new version</figcaption>
</figure>

Evolve resolves instability intelligently by rebasing unstable commits on a stable destination, in the case above **newb**.
But it **does not force the user to resolve the instability right away** and allows, therefore, to be more flexible when working with stacks.
Consider the following stack of commits:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/stack1.dot.svg" />
</figure>

A user can amend **b** or **c** without having to rebase **d**.

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/stack2.dot.svg" />
<figcaption>We rewrote b and c, so c' and d are now unstable</figcaption>
</figure>

And when everything looks good **changeset evolution** can figure out the right commands to run to end up with the desired stack:

<figure style="text-align:center">
<img style="display: block; margin: 0 auto" alt="Before running the amend command" src ="/assets/evolve/stack3.dot.svg" />
</figure>

If the user was not using changeset evolution, he or she would have to rebase every time anything changes in the stack.
Also, the user would have to figure out what rebase command to run and could potentially make mistakes!

## What I didn't cover

- Working collaboratively with stacks
- Markers defining multiple precursors (fold) and multiple successors (split)
- And a lot of other things

## How to install evolve and start playing with it

1. Install mercurial
2. Clone evolve's repository with `hg clone http://hg.netv6.net/evolve-main/`
3. Add the following configuration to you `~/.hgrc` with the correct path from
the repo you just cloned:

{% highlight ini %}
[extensions]
evolve = path to/evolve.py
{% endhighlight ini %}
