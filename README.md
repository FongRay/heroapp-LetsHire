[![Build Status](https://travis-ci.org/vmw-tmpst/heroapp-LetsHire.png?branch=master)](https://travis-ci.org/vmw-tmpst/heroapp-LetsHire) [![Code Climate](https://codeclimate.com/github/vmw-tmpst/heroapp-LetsHire.png)](https://codeclimate.com/github/vmw-tmpst/heroapp-LetsHire) [![Dependency Status](https://gemnasium.com/vmw-tmpst/heroapp-LetsHire.png)](https://gemnasium.com/vmw-tmpst/heroapp-LetsHire) [![Coverage Status](https://coveralls.io/repos/vmw-tmpst/heroapp-LetsHire/badge.png?branch=master)](https://coveralls.io/r/vmw-tmpst/heroapp-LetsHire)

# What's LetsHire?
--------------
LetsHire is a hero application for Tempest project. It provides a fancy web management console for recuriting, more specific, user can track job openings' lifecycle and candidates' interview progress easily through this web application.

Based on a fine-grained role-based access control, LetsHire demonstrates a easy-to-use web UI to users. Each user, with a different role, after successful login, can see his/her action items on the dashboard web page at first glance, furthermore, he/she can navigate to the action page directly, without the need to click lots of buttons or links.

# Introduction
--------------
LetsHire is written with Rails3 framework. It can run either on Platform such as VMware Tempest or Cloud Foundry, or in your local box. It uses PostgreSql preferably to store persistent data, such as candidate's resume. Since service binding logic is well-designed so you can easily bind it to other kind of database service, such as MySQL.

__Rails3__ is a web application development framework written in the Ruby language. It is designed to make programming web applications easier by making assumptions about what every developer needs to get started. It allows you to write less code while accomplishing more than many other languages and frameworks. LetsHire is constructed on top of the Rails3, relies heavily on Rails3 MVC model to implement the data access layer and the backend business logic. Besides these things, LetsHire also exposes some RESTful APIs, mobile applications can call these interfaces to update interview status.

__PostgreSql__ is used to act as RDMS to store persistent data, such as job opening information, candidate's resume. 

The web visual part of LetsHire is built by HTML/CSS/Javascript, the following major 3rd party libraries are introduced in LetsHire.

__Bootstrap__ is a front-end framework for faster and easier web development.

__jqplot-rails__ is a plotting and charting plugin for the jQuery Javascript framework, jqPlot produces beautiful line, bar and pie charts.

__jquery-rails__ is a gem to automate using jQuery with Rails 3.

# Installation
--------------
1. Download source code from github
    git clone git@github.com:vmw-tmpst/heroapp-LetsHire.git

## Prerequisites
--------------
1. ruby-1.9.3

## Run in your local box
--------------
1. Create the gem set for the project:
    + rvm use 1.9.3-p327@lets-hire --create

2. Run bundler:
    + bundle install

3. Start the server:
    + rails server

4. Run unit tests:
    + rake db:migrate
    + rake

## Run on Tempest or CloudFoundry
--------------
1. Install vmc and its extension
    + gem install vmc
    + gem install console-vmc-plugin

2. Login cloudfoundry environment
    + vmc target api.cloudfoundry.com
    + vmc login <email account> <password>

3. Create service instance
    + vmc create-service postgresql <service instance name>

4. Update RAILS_ROOT/manifest.yml
    + change the service instance name under 'services' section

5. Run bundler:
    + bundle package
    + bundle install
    + bundle exec rake assets:precompile

6. Push app to cloudfoundry
    + vmc push

## User initialization
--------------
access http://<host>:<port>/init through http POST request, then web browser will redirect a page to setup admin account.


The story between you and LetsHire web application starts from now on ...

# Usage
--------------
Login http://<host>:<port>/ with the admin account, after successful login web browser will redirect you to the dashboard page.

## User roles definition
--------------
There are 4 kinds of user roles, by default, each user has a 'interviewer' role. Let's category all kinds of operations which LetsHire allows us to do.

### Operations
A. create/update/delete users

B. create/update/delete job openings

C. create/update/delete candidates

D. arrange interviews

E. update interview feedback

### Roles
1. admin
    operation types: A, B, C, D

2. hiring manager
    operation types: B, C, D

3. recruiter
    operation types: C, D

4. interviewer
    operation types: E

## Departments management
--------------
Currently LetsHire provides separate web pages to manage jop openings/candidates/interviews, but does not provide any visual interface to manage departments. The departments value are fixed, see RAILS_ROOT/app/model/users DEFAULT_SET definition.
