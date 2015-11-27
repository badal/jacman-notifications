#!/usr/bin/env ruby
# encoding: utf-8

# File: base.rb, created 13/12/14
# extracted from notification, created: 21/08/13
#
# (c) Michel Demazure & Kenji Lefevre

module JacintheManagement
  # Methods for e-subscriptions notification
  module Notifications
    # tiers for notification
    Tiers = Struct.new(:tiers_id, :name, :ranges, :mails, :drupal, :drupal_mail)

    # subscription parameters to be notified
    # noinspection RubyConstantNamingConvention
    ToBeNotified = Struct.new(:id, :revue, :year, :ref, :billing, :tiers_id, :tiers_email)

    # reopening class
    class ToBeNotified
      # @return [String] explicit reference when special
      def reference
        case ref
        when /Abo..-GT/
          'gratuit/free'
        when /Abo..-Ech/
          'échange/exchange'
        when /Abo-Nat/
          'compris dans l\'abonnement national CNRS'
        else
          "ref:#{ref}"
        end
      end

      # @return [String] report for mail
      def report
        "#{revue} (#{year}) [#{reference}]"
      end
    end

    # base methods for notifications
    module Base
      # sql to extract tiers
      SQL_TIERS = SQLFiles.script('tiers_ip_infos')

      # sql to count electronic subscriptions to be notified
      SQL_SUBSCRIPTION_NUMBER = SQLFiles.script('subscriptions_number_to_notify')

      # sql to extract electronic subscriptions to be notified
      SQL_SUBSCRIPTIONS = SQLFiles.script('subscriptions_to_notify')

      # sql to update base after notification
      SQL_UPDATE = SQLFiles.script('update_subscription_notified')

      # @return [String] time stamp for files
      def self.time_stamp
        Time.now.strftime('%Y-%m-%d')
      end

      # tell JacintheD that subscription is notified
      # @param [STRING] subs_id subscription identity
      def self.update(subs_id)
        query = SQL_UPDATE
                .sub(/::abonnement_id::/, subs_id)
                .sub(/::time_stamp::/, time_stamp)
        Sql.query(JACINTHE_MODE, query)
      end

      # will be built and cached
      @all_jacinthe_tiers = nil
      @classified_notifications = nil

      ## base of all Jacinthe Tiers

      # @return [Array<Tiers>] list o/f all Jacinthe Tiers
      def self.build_jacinthe_tiers_list
        @all_jacinthe_tiers = []
        Sql.answer_to_query(JACINTHE_MODE, SQL_TIERS).drop(1).each do |line|
          items = line.split(TAB)
          parameters = format_items(items)
          @all_jacinthe_tiers[parameters[0]] = Tiers.new(*parameters)
        end
      end

      #
      # @return [Array<Tiers>]all Jacinthe tiers
      def self.all_jacinthe_tiers
        build_jacinthe_tiers_list unless @all_jacinthe_tiers
        @all_jacinthe_tiers
      end

      # @param [Array<String>] items split line form sql answer
      # @return [Array] parameters for Tiers struct
      def self.format_items(items)
        number = items[0].to_i
        name = items[2] == 'NULL' ? items[1] : items[2] + ' ' + items[1]
        ranges = clean_split('\\n', items[3])
        mails = clean_split(',', items[4].chomp)
        [number, name, ranges, mails]
      end

      # @param [String] sep separator
      # @param [String] string string to be split
      # @return [Array<String|nil>] formatted splitting of string
      def self.clean_split(sep, string)
        string.split(sep).delete_if { |item| item == 'NULL' }
      end

      # @param [Integer|#to_i] tiers_id tiers identification
      # @return [Tiers] this Tiers
      def self.find_tiers(tiers_id)
        all_jacinthe_tiers[tiers_id.to_i]
      end

      ## base of all pending notifications

      # count and return number of notifications to be done
      # @return [Integer] number of notifications to be done
      def self.notifications_number
        Sql.answer_to_query(JACINTHE_MODE, SQL_SUBSCRIPTION_NUMBER)[1].to_i
      end

      # @return [ArrayToBeNotified>] all ToBeNotified objects
      def self.all_notifications
        Sql.answer_to_query(JACINTHE_MODE, SQL_SUBSCRIPTIONS).drop(1).map do |line|
          items = line.chomp.split(Core::TAB)
          ToBeNotified.new(*items)
        end
      end

      # @return [Hash<ToBeNotified>] all ToBeNOtified objects by categories
      def self.build_classified_notifications
        table = {}
        all_notifications.each do |item|
          key = [item.revue, item.year]
          (table[key] ||= []) << item
        end
        @classified_notifications = table
      end

      # @return [Hash<ToBeNotified>] all ToBeNOtified objects by categories
      def self.classified_notifications
        build_classified_notifications unless @classified_notifications
        @classified_notifications
      end

      # @return [Array] all the categories of possible notifications
      def self.notification_categories
        classified_notifications.keys.sort
      end

      # @return [Array] all the categories of possible notifications
      def self.filtered_classified_notifications
        classified_notifications.select do |(_, year), _|
          Notifications.filter(year)
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME

  include JacintheManagement
  puts Notification::Base.notifications_number

end
