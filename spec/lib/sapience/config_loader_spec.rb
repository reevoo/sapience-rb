# encoding: utf-8
# frozen_string_literal: true

require "spec_helper"

describe Sapience::ConfigLoader do
  include FileHelper

  describe ".load_from_file" do
    subject(:load_from_file) { described_class.load_from_file }

    context "no file in the application config directory" do
      it "uses the default configuration" do
        expect(load_from_file).to eq(
        "defaults"    => {
          "log_level" => "info",
          "appenders" => [{
            "file" => {
              "file_name" => "log/development.log",
              "formatter" => "color",
            },
          }],
        },
        "development" => {
          "log_level" => "debug",
          "appenders" => [{
            "file" => {
              "file_name" => "log/development.log",
              "formatter" => "color",
            },
          }],
        },
        "production"  => {
          "log_level" => "warn",
          "appenders" => [{
            "file" => {
              "file_name" => "log/production.log",
              "formatter" => "json",
            },
          }],
        },
        "test"        => {
          "log_level" => "warn",
          "appenders" => [{
            "file" => {
              "file_name" => "log/test.log",
              "formatter" => "color",
            },
          }],
        })
      end
    end

    context "when sapience.yml file defined in the application" do
      before do
        create_file("config/sapience.yml",
          ["development:",
           "  log_level: debug",
           "  appenders:",
           "    - file:",
           "        io: STDOUT",
           "        formatter: json"])
      end

      after { delete_file("config/sapience.yml") }

      it "uses the default configuration" do
        expect(load_from_file).to eq(
          "development" => {
            "log_level" => "debug",
            "appenders" => [{
              "file" => {
                "io" => "STDOUT",
                "formatter" => "json",
              },
            }],
          })
      end
    end
  end
end
