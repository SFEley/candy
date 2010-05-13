# Candy

__"Mongo like candy!"__ -- _Blazing Saddles_

Candy's goal is to provide the simplest possible object persistence for the [MongoDB][1] database.  By "simple" we mean "nearly invisible."  Candy doesn't try to mirror ActiveRecord or DataMapper.  Instead, we play to MongoDB's unusual strengths -- extremely fast writes and a set of field-specific update operators -- and do away with the cumbersome, unnecessary methods of last-generation workflows.

Methods like `find`.

Or `save`.

## Overview

When you mix the **Candy::Piece** module into a class, the class gains a Mongo collection as an alter ego.  Objects are saved to Mongo the first time you set a property.  Any property you set thereafter is sent to Mongo _immediately_ and _atomically._  You don't need to declare the properties; we use `method_missing` to drive the getting and setting of any field you want in any record.  Or you can use the hashlike `[]` and `[]=` operators if that's more in your comfort zone.

    class Person
      include Candy::Piece
    end
    
    me = Person.new
    me.last_name = 'Eley'   # New record created and saved to Mongo
    me.id                   # => ObjectID(4bb606f9609c8417cf00004b) or thereabouts
    me[:height] = 67        # Or me.height = 67 -- either way, updates with a Mongo $set

### Embedded Documents

We got 'em.  Candy pieces can contain each other recursively, to any arbitrary depth.  There's no need for complex `has_and_belongs_to_many :through {:your => 'mother'}` type declarations.  Just assign an object or a bunch of objects to a field.  Hashes and arrays become Candy-aware analogues of themselves (**CandyHash** and **CandyArray**) with live updating and the same recursive embedding.  Non-Candy objects are serialized into a flat hash structure that retains their class and instance variables, so they can be rehydrated later.

    me.favorites = { composer: 'Yoko Kanno',
                     seafood: 'Maryland blue crabs',
                     scotch: ['Glenmorangie Port Wood Finish',
                              'Balvenie Single Barrel']}
    me.spouse = Person.piece(first_name: 'Anna', eyes: :blue)
    me.spouse.eyes            # => :blue
    me.favorites.scotch[1]    # => 'Balvenie Single Barrel'
                              
### Retrieval

Again, transparency is the key. The same `method_missing` tactic applies to class methods to retrieve individual records:

    Person.last_name('Smith')  # Returns the first Smith
    Person.age(21)             # Returns the first legal drinker (in the U.S.)
    Person(12345)              # Returns the person with an _id of 12345
    
Take note of that last example.  It's moderately deep magic, and we take care not to stomp on any class-like methods you've already defined.  But it's the simplest possible way to retrieve a record by ID.  `Person.first('_id' => 12345)` works too, of course.

### Collections

Some applications don't need to iterate through all records of a query; you might just need the first record from a queue or something.  When you do need them, the anonymous "sort of like an array, except when it isn't" encapsulation of collections in other ORMs is clunky and confusing.  So enumerable cursors live in their own **Candy::Collection** module, which you explicitly mix into a class and then link back to the **Candy::Piece** class:

    class People
      include Candy::Collection
      collects :person   # Declares the Mongo collection is 'Person'
    end                  # (and so is the Candy::Piece class)
    
    People.last_name('Smith')                         # Returns an enumeration of all Smiths
    People.age(19).sort(:birthdate, :down).limit(10)  # We can chain options
    People(limit: 47, occupation: :ronin)             # Or People.all(params) or People.new(params)
    People.each(|p| p.shout = 'Norm!')                # Where everybody knows your name...

You can also, of course, just do `People.new()` with a bunch of query conditions.  You don't need two separate hashes for your fields and your Mongo options; Candy knows which keys are MongoDB query options and will automatically separate them for you.  The collection module is really just a thin wrapper around a **Mongo::Cursor** and passes most of its behavior to the cursor -- so you can do `each`, `next`, et cetera.

**Q:** _Why can't I just have Person automatically link to People? I want my Raaaaails!_

**A:** Because including ActiveSupport as a dependency would be nuts, whereas pasting in my own table of plural inflections would merely double the code base. I'm not against magic, obviously, but that's expensive magic for little benefit. You'll just have to type those three lines of code yourself.

## Prerequisites

* **Ruby 1.9.x**  The code uses the [new hash syntax][2], UTF-8 encoding, and 1.9ish enumerable methods. No whining. If you're starting a _new_ project in mid-2010 or later and you're still using 1.8, you're hurting us all. And kittens. You don't want to hurt kittens, do you?

* **MongoDB 1.4+**  You could probably get away with 1.2 for _some_ functionality, but the new array operators and [findAndModify][3] were too useful to pass up. It's a safe and easy upgrade, so if you're not on the latest Mongo yet...  Well, you're not hurting kittens, but you're hurting _yourself._

* **mongo gem 0.19+** The Ruby gem seems to lag behind actual Mongo development by quite a bit sometimes. 0.19.1 is the latest at the time of this writing, and some commands (e.g. `findAndModify`) have been implemented in Candy because the gem doesn't have methods for them yet. We'll continue to streamline our code as the driver allows.
  
## Installation

Come on, you've done this before:

    $ sudo gem install candy
    
(Or leave off the _sudo_ if you're smart enough to be using [RVM][4].)

## Configuration

The simplest possible thing that works:

    class Zagnut
      include Candy::Piece
    end
    
That's it. Honest. Some Mongo plumbing is hooked in and instantiated the first time the `.collection` attribute is accessed:
 
    Zagnut.connection # => Defaults to localhost port 27017
    Zagnut.db         # => Defaults to your username, or 'candy' if unknown
    Zagnut.collection # => Defaults to the class name ('Zagnut')
    
You can override the DB or collection by providing name strings or **Mongo::DB** and **Mongo::Collection** objects. Or you can set certain module-level properties to make it easier for multiple Candy classes in an application to use the same database:

* **Candy.host**
* **Candy.port**
* **Candy.connection**
* **Candy.connection_options** (A hash of options to the Connection object)
* **Candy.db** (Can provide a string or a database object)

All of the above is pretty general-purpose. If you want to use this class-based Mongo functionality in your own projects, simply include `Candy::Crunch` in your own classes.

## Using It

The trick here is to think of Candy objects like OpenStructs.  Or if that's too technical, imagine the objects as thin candy shells around a chewy `method_missing` center:

    class Zagnut
      include Candy::Piece
    end
    
    zag = Zagnut.new      # A blank document enters the Zagnut collection
    zag.taste = "Chewy!"  # Properties are created and saved as they're used
    zag.calories = 600
    
    nut = Zagnut.taste ("Chewy!")  # Or Zagnut(taste: 'Chewy!')
    nut.calories          # => 600
    
    kingsize = Zagnut.new
    kingsize.calories = 900  # Or kingsize[:calories] = 900
    kingsize.ingredients = ['cocoa', 'peanut butter']
    kingsize.ingredients << ['corn syrup']
    kingsize.nutrition = { sodium: '115mg', protein: '3g' }
    kingsize.nutrition.fat = {saturated: '4g', total: '9g'}
    kingsize[:nutrition][:fat][:saturated]   # => '4g'
    
    class Zagnuts
      include Candy::Collection
      collects Zagnut
    end
    
    bars = Zagnuts      # Or Zagnuts.all or Zagnuts.new
    bar.count           # => 2
    sum = Zagnuts.inject {|sum,bar| sum + bar.calories}  # => 1500
    
Note that writes are always live, but reads hold onto the retrieved document and cache its values to avoid query delays.  You can force a requery at any time with the `refresh` method.  (An expiration feature wherein documents are requeried after a set time has elapsed is being considered for the future.)

## Advanced Classes

Candy properties are fundamentally just entries in a hash, with some hooks to the MongoDB `$set` updater when something changes.  The primary reason we've implemented Candy as modules is so that you keep control of your own classes' behavior and inheritance.  To have properties that _don't_ store to the Mongo collection, all you have to do is define them explicitly:

    class Weight
      include Candy::Piece
      
      attr_accessor :gravity  # This won't be stored in MongoDB
      
      def kilograms
        pounds * 2.2046  # 'pounds' is undeclared, so Candy retrieves it
      end

      def kilograms=(val)
        self.pounds = val/2.2046  # 'pounds=' is undeclared; Candy stores it
      end 
    end
     
Embedded hashes are of type **CandyHash** unless you explicitly assign an object that includes **Candy::Piece**.  (CandyHash itself is really just a Candy piece that doesn't store its classname.)  If you want truly quick-and-dirty persistence, you can even just use a CandyHash as a standalone object and skip creating your own classes:

    hash = CandyHash.new(foo: 'bar')
    hash[:yoo] = :yar   # Persists to the 'candy' collection by default
    hash.too = [:tar, :car, :far]
    
    hash2 = CandyHash(hash.id)
    hash2.foo       # => 'bar'
    hash2.yoo       # => :yar
    hash2[:too][1]  # => :car
    
Embedded arrays are of type **CandyArray**.  Unlike CandyHashes, CandyArrays do _not_ include **Candy::Piece** and cannot operate as standalone objects.  They only make sense when embedded in a Candy piece.  That's just the way Mongo works.

## Good Practices

_(I'm not going to call them "Best" practices because you might think of better ones than me.)_

### Validations

The long-term plan includes support for ActiveModel features as an optional extension.  In the meantime, one simple trick is to decorate your properties:

  class Person
    include Candy::Piece
    
    def email=(val)
      raise "Invalid email address!" if val !~ /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
      super
    end
  end

_Exceptions for validation failures?_ Why yes. One consequence of a doctrine of instant persistence is that _not_ persisting connotes something's wrong. I personally prefer rescues to deeply nested 'else' clauses to handle failures anyway.  If you disagree, you could implement the above in a kinder, gentler way:

    def email=(val)
      if val =~ /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
        super
      else
        (@errors ||= []) << "Invalid email address!"
        false   # (Or nil, but that gets confusing if you can actually assign nil.)
      end
    end

If that seems like a lot of work compared to `validates_format_of` -- well, you're right. As I said, it's coming.  In the meantime, just don't validate frivolously.  Leave minor tips and cleanups to the interface layer, and only refuse to save in cases where allowing the value would break something.

### Named Scopes

Dirt simple.  Use a method in the collection class.

    class People
      include Candy::Collection
      collects :person
      
      def voters
        age('$gt' => 18).citizen(true)
      end
    end

### Required Fields

Instant document creation makes it problematic to wait to see if a user's going to fill in a field.  One tactic is to require those fields in the constructor:

    class Person
      include Candy::Piece
      def initialize(options={})
        raise "Last name is required!" unless options[:last_name]
        raise "Email address is required!" unless options[:email]
        super
      end
    end
    
    p = Person.new(last_name: 'Eley', email: 'sfeley@gmail.com')   # This is valid
    
Or you can use the above scoping trick to make sure your application's standard collections operate only on records that are "complete."  You could even make it intrinsic to the class itself:

    class ValidPeople < People
      def initialize(options={})
        options.merge!(last_name: {'$exists' => true}, email: {'$exists' => true})
        super
      end
    end


## Philosophy

Even relative to other ORMs, Candy's pretty opinionated.  Here are some of the opinions behind the design.

* Applications should be beautiful.

* In a beautiful application, most of the code clearly and obviously furthers primary activities.  (Business needs, use cases, user stories, the critical path, call it whatever you want.)

* Data storage is not a primary activity.  It's a supporting activity.  It's something you have to do so that the primary activities you do today remain done tomorrow.

* An application structure which reflects the constraints of supporting activities more than the achievement of primary activities is not beautiful.

* Current Ruby ORMs go a long way towards eliminating the boilerplate cruft found in other languages' frameworks.  But they don't go far _enough._

* `Save` sucks.  The 'write-now-commit-later' pattern of most ORMs creates brittleness and uncertainty.  If I change the state of something, _I want it changed._  My framework shouldn't hold its breath waiting for me to say "Simon Says."

* Frameworks should be beautiful.

* A beautiful framework is one whose fundamentals can be read and understood by a journeyman developer with appropriate background knowledge in one sitting.

* Frameworks that are too large or complex to be beautiful can sometimes be broken down into smaller frameworks that _are_ beautiful.

* Beautiful frameworks should be transparent and non-constraining.  A _truly_ beautiful framework is one you have to squint to see.
 
* _Magic_ (defined as "behavior whose workings are not immediately apparent") is fine in a framework. In a sense it's what frameworks _are._  But magical behavior should be restrained, consistent, clearly documented, and must not violate the Principle of Least Surprise.

* Thomas Jefferson wrote that software frameworks should be subject to revolution every couple of years.  ("The tree of agility must be refreshed from time to time with the blood of senior architects and project managers.  It is its natural manure.")  I will be disappointed if Candy is not roundly decried for being too complex, bloated, and intrusive by 2013 at the latest.

* There is a finite amount of seriousness allowed in any open source project.  A project that takes itself too seriously is using up its reserves, and is less likely to be taken seriously by its user base.

* A project that appeals to playfulness is more likely to be explored with vigor, and if it withstands the exploration, creates _passion._

* A README with this many bullet points in a single list should probably stop.

## Caveats, Limitations, and To-Dos

This is very, very alpha software.  I'm using it in some non-trivial projects right now, but it's far from bulletproof, and a lot of things aren't implemented yet.  In particular:

* The API is still in flux and subject to overhauling, undermining, or carpetbombing at any time.  Candy v0.2, for instance, has barely a wisp of resemblance to Candy v0.1.  (My apologies to the 155 of you who downloaded 0.1.)

* CandyHashes and CandyArrays don't yet implement the full set of methods you'd expect from hashes and arrays.  I mean to flesh them out to make them more compatible.  (You can help by creating issues to tell me what methods you need most.)

* Collections are not terribly robust nor well-tested yet.  They 'work' in the sense that they pass a bunch of things to **Mongo::Cursor**, but I personally consider the cursor functionality to be a bit wonky.  I'd like to make enumerations more repeatable and have the cursors more certain to be released after garbage collection.

* Currently every property assignment is a separate write to the database (mostly using **$set**.)  This is fine, but for cases where a lot of properties are set at once we will eventually have transaction-like behavior using blocks.

* Many Mongo update operators, such as **$pushAll** and **$pop** and **$addToSet**, are not implemented yet or are not fully leveraged.  (Saving a full document isn't implemented either, but that's a deliberate feature.)

* For high-concurrency use cases or for huge documents, more control of the document caching is called for.  I'd like to have an option to declare only certain fields to be retrieved by default, and have the internal cache expire after a set time or clear itself on every read.

* 'Safe mode' is never used.  Making it an option for classes or specific updates would be...well...safer.

* There's no support yet for deleting records, apart from driver calls on the class's collection.  Somebody might want to someday.

* Index creation is currently left as an exercise to be performed out-of-band.  I do believe a proper persistence framework, even a transparent one, should have some facility for it.

* Likewise, there's no way yet to set interesting collection options (capped collections, etc.) except to make the **Mongo::Collection** object separately and hand it to the class.

* For that matter, capped collections haven't been tested at all and might operate weirdly if properties are continually being set on them.

* I have only begun optimizing for code beauty, and have not optimized at all yet for performance.  Mongo is fast.  I make no guarantees that my _code_ is fast at this time.

* I haven't tested it at all in Windows.  Witness my regret.  (Wait, there isn't any.)

* This library isn't thread-safe yet.  (Which is to say: I haven't tried to confirm one way or the other, but I'd be shocked if it was.)

* There's no support yet for ActiveModel or similar validations, et cetera.  It's on my list to create an extension system, with Rails 3 and ActiveModel support being the first use case.  Right now this is more of a Sinatra sort of data thingy than a Rails data thingy.

## Resources

We have the usual array of stuff for your learning pleasure...

* **Home page:** <http://github.com/SFEley/candy>
* **Documentation:** <http://rdoc.info/projects/SFEley/candy>
* **Report issues:** <http://github.com/SFEley/candy/issues>
* **Discussion list:** <http://groups.google.com/group/candy-users>

## Contributing
 
At this early stage, one of the best things you could do is just to tell me that you have an interest in using this thing. Join the [discussion list][5] and let us know what you think. 

Beyond that, report issues, please.  If you want to fork it and add features, fabulous.  Send me a pull request.

Oh, and if you like science fiction stories, check out my podcast [Escape Pod](http://escapepod.org).  End of plug.

## License

This project is licensed under the [Don't Be a Dick License][6], version 0.1, and is copyright 2010 by Stephen Eley. See the [LICENSE.markdown][6] file for elaboration on not being a dick.  (But you probably already know.)

[1]: http://mongodb.org
[2]: http://snippets.dzone.com/posts/show/7891
[3]: http://www.mongodb.org/display/DOCS/findandmodify+Command
[4]: http://rvm.beginrescueend.com/
[5]: http://groups.google.com/group/candy-users
[6]: http://github.com/SFEley/candy/blob/master/LICENSE.markdown