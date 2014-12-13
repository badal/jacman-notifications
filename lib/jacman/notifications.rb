#!/usr/bin/env ruby
# encoding: utf-8

# File: notifications.rb
# Created: 13/12/2014
#
# (c) Michel Demazure <michel@demazure.com>

require 'jacman/core'

require_relative('notifications/notification_base.rb')
require_relative('notifications/notification.rb')
require_relative('notifications/notifier.rb')

module JacintheManagement
  module Notifications
    TAB = Core::TAB
    REAL = false
  end
end
