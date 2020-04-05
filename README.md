# Sorbet Duck

Sorbet Duck is a
**tool which adds statically-checked duck typing (sometimes called structural typing) to Sorbet using static code generation**. This means you can
**define a Sorbet type which accepts any object with a particular method**.

Suppose we wanted to define our own `empty?` function, and allow it to accept
absolutely any object which has a `length` method returning an Integer. This
isn't possible in pure Sorbet (you'd need to explicitly implement an interface
on all types passed in), but you can do it with Sorbet Duck! It looks like this:

```ruby
# Define our statically-checked duck type
#      ,--- A name to describe what this type is checking for
#      |            ,--- The method to check for
#      |            |             ,--- The expected sig body of that method
#     .-------.   .----.    .--------------.
duck(:HasLength, :length) { returns(Integer) }
#               
#                     ,--- Now use our duck type!
#               .-------------.
sig { params(x: Duck::HasLength).returns(T::Boolean) }
def empty?(x)
    x.length == 0
end

# Later...
empty?([1, 2, 3]) # passes static type check
empty?("hello")   # also passes
empty?(64)        # fails static type check - there is no Integer#length method
```

Sorbet Duck runs as a pre-processing step before Sorbet, generating a single
Ruby file which creates interfaces and implements them where required.

This works using Sorbet's LSP implementation to detect what new interface
implementations are needed, then dynamically generates them using
[Parlour](https://github.com/AaronC81/parlour).

This is **absolutely not production-ready**: it has no formal tests, has
several limitations (see below), and is all-round a bit clunky. Still, it's an
interesting proof-of-concept to show that some amount of duck typing is possible
in Sorbet.

## Limitations
- **The method specified for the duck type can't take parameters**. This should
  be fairly easy to implement, but I haven't got round to it yet.
- The only methods supported for the duck type are instance methods on classes.
- The duck type can only specify a single method requirement.

## Usage
1. Add `sorbet_duck` to your Gemfile/gemspec and install it
2. Make sure you require `sorbet_duck`, like you would require `sorbet-runtime`
3. Define your duck types as shown in the example above
4. Run `srb-duck` in the root of your project to generate `duck.rb` (don't
   require `duck.rb` at runtime, this is entirely for static checking)
5. Run `srb tc` to typecheck your project

You **must run `srb-duck` before every time you run `srb tc`** to regenerate
`duck.rb`. If you want to make this easy, you could always create a Rake task
which runs one after the other.

## Implementation
First of all, no waterfowl were harmed in the creation of this gem.

This works by generating an interface for each defined duck type (like
`HasLength` in that usage example), and then implementing that interface for any
type we attempt to pass into a method accepting that duck type. The interfaces
and implementations are written into `duck.rb`. (This can't be `duck.rbi` and
I'm not entirely sure why...)

The process of doing this is roughly as follows:

1. Find all duck type definitions (usages of `duck`) by searching the project's
   AST with the `ffast` gem
2. Define interfaces corresponding to these duck types in Parlour's RBI object
   tree
3. Write that to a file so the interfaces are resolvable by Sorbet
4. Launch Sorbet's LSP implementation, connect to it, and use the type errors
   to find which types have been passed into methods accepting duck types
5. Implement the corresponding duck type interfaces for those types, saving
   these implementations to Parlour's RBI object tree

## Troubleshooting
- You must be using Bundler! Sorbet Duck invokes some shell commands which
  assume `bundle exec` is available.
- If Sorbet ever generates `hidden-definitions` or similar for the `Duck` 
  module, it'll stop typechecking correctly.