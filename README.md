# Ethnic LA

Facilitating the discovery of ethnic groups in Los Angeles by making data about languages, cultures, and their location more accessible. We hope to promote cultural understanding through enabling more cross-cultural interactions.

## Running Tests

This project uses the caybara-webkit driver for Rails system tests which has a
dependency on QT. This dependency must be installed for system tests to run.
Follow instructions [here](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit).
Once all dependencies are installed and the database has been set up, run system
tests with `rails test:system`. All other tests can be run as usual with
`rails test`.
