#!/usr/bin/env ruby
# encoding: utf-8

# File: notifications.rb
# Created: 13/12/2014
#
# (c) Michel Demazure <michel@demazure.com>

require 'jacman/core'

require_relative('notifications/base.rb')
require_relative('notifications/register.rb')
require_relative('notifications/selector.rb')
require_relative('notifications/notifier.rb')
require_relative('notifications/version.rb')

module JacintheManagement
  module Notifications
    TAB = Core::TAB
    REAL = false
  end
end
