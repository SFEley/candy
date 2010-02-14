# Candy

__"Mongo like candy!"__ — _Blazing Saddles_

Candy aims to be the simplest possible ORM for the MongoDB database. If MongoMapper is Rails, Candy is Sinatra. Mix the Candy module into any class, and every new object for that class will create a Mongo document. Objects act like OpenStructs -- you can assign or retrieve any property without declaring it in code.

Other distinctive features:

* Sane defaults are used for the connection, database, and collection.  If you're running Mongo locally you can have zero configuration.
* Candy has no `save` or `save!` method. Property changes are persisted to the database immediately. Mongo's atomic update operators (in particular $set) are used so that updates are as fast as possible and don't clobber unrelated fields.
* Candy properties have _no memory._ Every value retrieval goes against the database, so your objects are never stale. (You can always implement caching via Ruby attributes if you want it.)
* Query result sets are Enumerator objects on top of Mongo cursors. If you're using Ruby 1.9 you'll get very efficient enumeration using fibers. 
* Whole documents are never written nor read. Queries only return the **_id** field, and getting or setting a property only accesses that property.
* __Coming soon:__ Array and embedded document operations.
* __Coming soon:__ A smart serializer (Candy::Wrapper) to convert almost any object for assignment to a Candy property.

Candy was extracted from [Candygram](http://github.com/SFEley/candygram), my delayed job system for MongoDB.  I'm presently in the middle of refactoring Candygram to depend on Candy instead, which will simplify a lot of the Mongo internals.

## Installation

Come on, you've done this before:

    $ sudo gem install candy
    
Candygram requires the **mongo** gem, and you'll probably be much happier if you install the **mongo\_ext** gem as well. The author uses only Ruby 1.9, but it _should_ work in Ruby 1.8.7. If it doesn't, please report a bug in Github's issue tracking system. (If you're using 1.8.6, I hosed you by using the Enumerator class. Sorry. I might fix this if enough noise gets made.)

## Configuration

The simplest possible thing that works:

    class Zagnut
      include Candy
    end
    
That's it. Honest. Some Mongo plumbing is hooked in and instantiated the first time the `.collection` attribute is accessed:
 
    Zagnut.connection # => Defaults to localhost port 27017
    Zagnut.db         # => Defaults to your username
    Zagnut.collection # => Defaults to the class name ('Zagnut')
    
You can override the DB or collection by providing new name strings or Mongo::DB and Mongo::Collection objects. Or you can set certain global variables to make it easier for multiple Candy classes in an application to use the same database:

* **$MONGO_HOST**
* **$MONGO_PORT**
* **$MONGO_OPTIONS** (A hash of options to the Connection object)
* **$MONGO_DB** (A simple string with the database name)

All of the above is pretty general-purpose. If you want to use this class-based Mongo functionality in your own projects, simply include `Candy::Crunch` in your own classes.

## Using It

The trick here is to think of Candy objects like OpenStructs.  Or if that's too technical, imagine the objects as thin candy shells around a chewy `method_missing` center:

    class Zagnut
      include Candy
    end
    
    zag = Zagnut.new      # A blank document enters the Zagnut collection
    zag.taste = "Chewy!"  # Properties are created and saved as they're used
    zag.calories = 600
    
    nut = Zagnut.first(:taste => "Chewy!")
    nut.calories          # => 600
    
    kingsize = Zagnut.new
    kingsize.calories = 900
    
    bars = Zagnut.all     # => An Enumerator object with #each and friends 
    sum = bars.inject {|sum,bar| sum + bar.calories}  # => 1500
    

If, in the middle of that code execution, somebody else changed the properties of one of the objects, you might get different answers. Every property access requeries the Mongo document. That sounds insane, but Mongo is _fast_ so we can get away with it; and it avoids any brittleness or complexity of having refresh methods or checking for stale data. (Later versions may include more document-based access via block operations. Let me know if you would like to see that.)

### Method_missing?  _Really?_

Yes.  It may seem at first like an inversion: Candy only stores attributes that you _don't_ declare in your class definition.  But there's a method to this madn...  (No, wait, it's missing.)

Here's the reason. I have no idea what kind of logic you might want to put in your classes. I don't want to guess what you want to store or not -- and more to the point, I don't want to make _you_ guess.  Unless you want to.

Candy properties are dumb.  They don't have calculations. They don't memoize or cache. They have nothing to do with instance variables. If you _want_ to make something smarter, just set up your accessors and have them talk to  Candy behind the scenes:

    class Zagnut
      include Candy
      
      def weight
        @weight ||= _weight  # _weight is undeclared, so Candy looks it up
      end

      def weight=(val)
        self._weight = @weight = val   # _weight= is undeclared, so Candy stores it
      end      
    end
        
    
== Contributing
 
At this early stage, one of the best things you could do is just to tell me that you have an interest in using this thing. You can email me at sfeley@gmail.com -- if I get more than, say, three votes of interest, I'll throw a projects page on the wiki.

Beyond that, report issues, please.  If you want to fork it and add features, fabulous.  Send me a pull request.

Oh, and if you like science fiction stories, check out my podcast [Escape Pod](http://escapepod.org).  End of plug.

== Copyright

Copyright (c) 2010 Stephen Eley. See LICENSE for details.
