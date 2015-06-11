#!/usr/bin/env ruby
# encoding: utf-8

# File: register, created 13/12/14
# extracted from notification, created: 21/08/13
#
# (c) Michel Demazure & Kenji Lefevre

module JacintheManagement
  # Methods for e-subscriptions notification
  module Notifications
    NO_MAIL_FILE = File.join(Core::DATADIR, 'tiers_sans_mail.txt')

    # methods to register tiers without mail
    module Register
      # list to register Tiers with subscriptions but without mail
      @register = [['Id', 'Nom', 'Nombre', 'Plages ?'].join(Core::TAB)]

      # Register a line
      # @param [String] line line to be registered
      def self.register(line)
        @register << line
      end

      # @return [Array<String>] register content
      def self.all
        @register
      end

      # save the list of registered Tiers in a csv file
      def self.save_register
        File.open(NO_MAIL_FILE, 'w:utf-8') do |file|
          sum = 0
          @register.each do |line|
            file.puts(line)
            sum += line[2].to_i
          end
          file.puts(['', '', sum, ''].join(TAB))
        end
        "Fichier : #{NO_MAIL_FILE}"
      end

      # Report how many users w/o mail
      def self.report_without_mail
        number = @register.size - 1
        return [] if number == 0
        answer = save_register
        "#{number} abonné(s) dépourvu(s) d'adresse mail\n" + answer
      end
    end

    # open in editor tiers without mail file
    def self.show_tiers_without_mail
      Utils.open_in_editor(NO_MAIL_FILE)
    end

    # @return [String] number of tiers without mail and number of subscriptions
    def self.tiers_without_mail
      lines = File.open(NO_MAIL_FILE, 'r:utf-8').readlines
      "#{lines.size - 2}/#{lines.last.split(TAB)[2]}"
    end
  end
end
