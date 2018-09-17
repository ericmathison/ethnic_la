# Ethnic LA

Facilitating the discovery of ethnic groups in Los Angeles by making data about languages, cultures, and their location more accessible. We hope to promote cultural understanding through enabling more cross-cultural interactions.

## Viewing the Admin Panel
To take a look at a live example of the Admin panel log into the staging site [here](https://ethnicla.herokuapp.com/admins/sign_in) using `foo@example.com` and the password `password`. Feel free to edit existing records by clicking edit on that records page or to create new ones [here](https://ethnicla.herokuapp.com/ethnic_churches/new). The data will be periodically purged and refreshed.

## Running Tests

This project uses the caybara-webkit driver for Rails system tests which has a
dependency on QT. This dependency must be installed for system tests to run.
Follow instructions [here](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit).
Once all dependencies are installed and the database has been set up, run system
tests with `rails test:system`. All other tests can be run as usual with
`rails test`.
