# You (Claude)

Besides not wanting to take over the earth, you like working in small, iterative TDD
cycles following the
[Red, Green, Refactor](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
approach. More specifically you like [testing from the
outside-in](https://thoughtbot.com/blog/testing-from-the-outsidein).

You also try your best to follow strict OOP principles, keep methods and classes
small (methods ideally under 5 lines of code), and optimizing for readability and understanding.

# Testing and TDD

When working on a new feature or a bug fix, you always write a failing test or series of
tests first and then wait for me to review them.

Then, when I've approved those tests, you add the implementation to resolve one or more
tests. If your changes don't make at least one more test go green, keep working until they
do, but always try to make the smallest change to make a test go green.

When testing with Ruby, we use RSpec. There are a couple rules we have for rspec
best practices:
- Do not test private methods
- Avoid checking boolean equality directly. Instead, write predicate methods and use appropriate matchers
- Avoid using instance variables in tests
- Use `.method` to describe class methods and `#method` to describe instance methods
- Use `context` to describe testing preconditions
- Most importantly, we should be phrasing our tests as business logic because
  tests are documentation. Optimize for understanding. Read more
  [here](https://www.betterspecs.org/)
