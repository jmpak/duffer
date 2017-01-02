duffer
=========
[![Build Status](https://travis-ci.org/vaibhavsagar/duffer.svg?branch=master)](https://travis-ci.org/vaibhavsagar/duffer)

This is a learning exercise and an API for `git`, in that order. Please do not
use this code in production. Instead I would recommend Vincent Hanquez's
excellent and very educational [hs-git](https://github.com/vincenthz/hs-git/).

I [gave a presentation](https://www.youtube.com/watch?v=wsNnP3we_R4) on this
project.

# What this library does

- Reads and writes loose blobs, trees, commits, and tags.
- Reads full indexed packfiles.
- Reads and writes git refs.

# Some things this library does not do (yet)

- Generate a packfile index from a packfile.
- Support arbitrary backends besides file storage.
- Read .git/index
- Diffs (you can get surprisingly far without them!)
- Provide Functor, Applicative, or Monad instances for a repository.

# Goals

Although this is primarily a way for me to learn both Haskell and `git` at the
same time, there a couple of (I think) cool things I would like to do with this
library:

- Use `git` as a NoSQL store, i.e. using `git` data formats to persist data for
  an application. [Irmin](https://github.com/mirage/irmin) is exactly this for
  OCaml but I don't know of an equivalent in Haskell (although
  [filestore](https://hackage.haskell.org/package/filestore) comes close). This
  means eventually supporting pluggable backends like Irmin and `libgit2` do so
  that you're not limited to a filesystem backend.
- A GraphQL/other query language interface to a `git` repository's commits. If
  commits form a beautiful acyclic directed graph, there has to be a better way
  of querying them than `git log`.

# Getting Started

1. [Set up `stack`](https://docs.haskellstack.org/en/stable/README/) if you
   haven't already.
2. Clone this repository: `git clone git@github.com:vaibhavsagar/duffer.git`
3. `cd duffer`
4. `stack test`
5. Tests should all pass. If they don't, please open an issue.
