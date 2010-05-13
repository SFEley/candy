Candy History
=============

This document aims to provide only an overview.  Further, we've only really been tracking things since **v0.2**.  For obsessive detail, just check out the `git log`.

v0.2.8 - 2010-05-13 (the "Holy crap, that was ten pomodoros" release)
---------------------------------------------------------------------
Major refactoring to fix a major bug: embedded documents weren't being loaded properly on document retrieval.  This resulted in a lot of code being moved around, and some regrettable circular connascence between Piece and Wrapper that I hope to address later.  Overall, though, it's simpler now.

**API CHANGE:** The `.embed` class method has two new required parameters and is now used _only_ when you know the parent you want to embed something in.  To make a Candy piece that you don't want to be saved right away, use `.piece` instead.

* Fixed Github issue #11

v0.2.7 - 2010-05-05 (the "yes, you MAY put your peanut butter in my chocolate" release)
--------------------------------------------------------------------------------------
Found and fixed a convoluted bug that was preventing embedded Candy objects from being saved properly. (It was treating them as _non_-Candy objects, which makes the world a gray and boring place.) While I was at it, refactored some methods and chipped away at some complexity.

**MODERATELY BREAKING CHANGE ALERT:** I've renamed the `to_mongo` and `from_mongo` methods to `to_candy` and `from_candy`.  The initial reason for the _mongo_ names was for some vague semblance of compatibility with [MongoMapper](http://github.com/jnunemaker/mongomapper), but that doesn't make sense since we're treating serialized Candy objects completely differently and expecting them to unpack themselves. I seriously doubt anyone was using these methods yet, but just in case, now you know.

* Fixed embedding bug on Candy objects

v0.2.6 - 2010-05-03 (the "Spanish Fly" release)
-----------------------------------------------
Thanks to [xpaulbettsx](http://github.com/xpaulbettsx) for pointing out in issue \#4 that Candy was attempting to connect to localhost prematurely.  
A stray setting of the collection name in CandyHash was the culprit, causing a cascade of lookups.  Refactored to maintain lazy evaluation of the whole MongoDB object chain, and while I was at it, moved most of the interesting objects into `autoload` conditions in the main Candy file instead of `require`.

* Reorganized for autoloading
* Fixed issue #4 - tries to connect to host immediately on require


v0.2.5 - 2010-05-02 (the "John::Jacob::Jingleheimer::Schmidt" release)
----------------------------------------------------------------------
As I was building an app based on several Sinatra building blocks, I realized that Candy was creating collection names like **Login::Person** and **Profile::Person** with complete module namespaces.  I wanted both of those **Person** classes to be different views on the same data, and having to override the collection name each time was becoming a pain.  I'm not sure that fully namespacing the collection names inside Mongo has much value, and we weren't really documenting that it was happening, so I've simplified things.

* Default collection names no longer include module namespace paths


v0.2.4 - 2010-04-21 (the "No shortcuts!" release)
------------------------------------------------- 
While building validations and custom behavior on a new app, I realized that
any method overrides in my classes were being bypassed if I passed the values
in a hash to .new() -- it was just setting everything straight in Mongo.
Inconsistent behavior is uncool. So now every hash key calls the relevant
assignment method in the class.

* Values passed in hash to new objects call the relevant assignment methods
* Fixed typo in README (thanks, kfl62)


v0.2.3 - 2010-04-13 (the "around and around we go") release
-----------------------------------------------------------
Turns out some Rails environments get really ornery if you introduce circular dependencies into your code.  Like, say, requiring 'candy/hash' inside 'candy/piece' and 'candy/piece' inside 'candy/hash'.  Who knew?

(Rhetorical question.  _I_ should have known.  I'll restructure later to remove the breakage.)

* Stubbed out Candy::Piece to resolve circular dependency issue


v0.2.2 - 2010-04-12 (the "I hate reporting bugs to the MongoDB team" release)
-----------------------------------------------------------------------------
The Mongo gem has broken the BSON functions out into a separate bson gem, so I had to fix things.  This means Candy is no longer compatible with the Mongo gem < 0.20.1.  Que sera.  (Also, the bson_ext gem **must** be installed due to a bug.  I'll remove the dependency when they fix it.)  Additional minor bonus: authentication.

* New BSON::* classes correctly referenced in Candy::Wrapper
* Candy.username and Candy.password properties to automatically authenticate at the global level
* Class-specific .username and .password properties for class-specific databases


v0.2.1 - 2010-04-04 (the "Oops" release)
----------------------------------------
I screwed up in my use of Jeweler, and managed to get my versions out of sync between Github and Rubygems.org.  I tried to `gem yank` the one from Rubygems, but it won't let me push again with the same version number.  To justify bumping the patch number, I added this changelog.  Yeah, I know.  Pathetic.

* The HISTORY file you're reading


v0.2.0 - 2010-04-04 (the "Candy for Easter" release)
----------------------------------------------------
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


v0.1 - 2010-02-16
-----------------
Let's just call this one a "proof of concept" release.  It worked, but clumsily.  Only Candy::Piece was really implemented, with no embedding, and the bulk of the code was directly in `method_missing`.  Global variables like **$MONGO_HOST** were used instead of module properties, and the separation of driver and framework concerns was nonexistent.  Please don't look at it.  You'll make me blush.