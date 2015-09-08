#!/usr/bin/env ruby
# encoding: utf-8

# File: registry, created 13/12/14, modified 3/9/2015
# extracted from notification, created: 21/08/13
#
# (c) Michel Demazure & Kenji Lefevre

module JacintheManagement
  # Methods for e-subscriptions notification
  module Notifications
    NO_NOTIFICATION_FILE = File.join(Core::DATADIR, 'notifications_non_faites.txt')

    # methods to register missed notifications
    module Registry
      # lists to register subscriptions by Tiers without mail
      TITLES = %w(Abonnement Revue Année Référence Facture Tiers Mail)

      @registry_with_ranges = [['AVEC DES PLAGES'], TITLES]
      @registry_without_ranges = [['SANS PLAGES'], TITLES]

      # register the error
      # @param [ToBeNotified] sub non notified
      # @param [Bool] ranges whether the tiers has IP ranges
      def self.register_error(sub, ranges)
        if ranges
          @registry_with_ranges << sub.to_a
        else
          @registry_without_ranges << sub.to_a
        end
      end

      # save the list of missed notifications in a csv file
      def self.save_registry(full_list)
        File.open(NO_NOTIFICATION_FILE, 'w:utf-8') do |file|
          full_list.each do |line|
            file.puts(line.join(TAB))
          end
        end
      end

      # @return [[Array<Array>, Integer]] full_list to be saved, number of errors
      def self.build_full_list
        full_list = []
        with_size = @registry_with_ranges.size
        without_size = @registry_without_ranges.size
        full_list += @registry_without_ranges if without_size > 2
        full_list += @registry_with_ranges if with_size > 2
        [full_list, without_size + with_size - 4]
      end

      # Report how many missed notifications
      # @return [String] report
      def self.report_missed_notifications
        full_list, size = *build_full_list
        if size == 0
          'Toutes les notifications ont été envoyées'
        else
          save_registry(full_list)
          "#{size} notifications non faites"
        end
      end

      # open in editor the missed notifications file
      def self.show_missed_notifications
        Utils.open_in_editor(NO_NOTIFICATION_FILE)
      end
    end
  end
end
