#!/usr/bin/env ruby
# encoding: utf-8

# File: notifications.rb
# Created: 13/12/2014
#
# (c) Michel Demazure <michel@demazure.com>

require_relative('notifications/version.rb')
require_relative('notifications/base.rb')
require_relative('notifications/register.rb')
require_relative('notifications/selector.rb')
require_relative('notifications/notifier.rb')

module JacintheManagement
  module Notifications
    TAB = Core::TAB
    FAKE = (RUBY_PLATFORM =~ /mswin|mingw/)
  end
end
