# Candy History

This document aims to provide only an overview.  Further, we've only really been tracking things since **v0.2**.  For obsessive detail, just check out the `git log`.

## v0.2.1 - 2010-04-04 (the "Oops" release)

I screwed up in my use of Jeweler, and managed to get my versions out of sync between Github and Rubygems.org.  I tried to `gem yank` the one from Rubygems, but it won't let me push again with the same version number.  To justify bumping the patch number, I added this changelog.  Yeah, I know.  Pathetic.

* The HISTORY file you're reading

## v0.2.0 - 2010-04-04 (the "Candy for Easter" release)

A nearly total rewrite.  Some specs still remain from v0.1, but very little actual code.  Added in this release were:

* Candy::Collection
* Candy::CandyHash
* Candy::CandyArray
* Dynamic class methods for finders
* Object embedding
* Module-level configuration properties (`Candy.host`, `Candy.db`, etc.)
* A novel-length README file
* The Don't Be a Dick License
* Other stuff I've surely forgotten about

## v0.1 - 2010-02-16

Let's just call this one a "proof of concept" release.  It worked, but clumsily.  Only Candy::Piece was really implemented, with no embedding, and the bulk of the code was directly in `method_missing`.  Global variables like **$MONGO_HOST** were used instead of module properties, and the separation of driver and framework concerns was nonexistent.  Please don't look at it.  You'll make me blush.