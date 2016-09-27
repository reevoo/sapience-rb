# encoding: utf-8
# frozen_string_literal: true

require "spec_helper"

describe Sapience::ConfigLoader do
  include FileHelper

  describe ".load_from_file" do
    subject(:load_from_file) { described_class.load_from_file }

    context "no file in the application config directory" do
      shared_examples "loading default configuration" do
        it "uses the default configuration" do
          expect(load_from_file).to eq(
          "default"    => {
            "log_executor" => "single_thread_executor",
            "log_level" => "info",
            "appenders" => [{
              "stream" => {
                "io" => "STDOUT",
                "formatter" => "color",
              },
            }],
          },
          "development" => {
            "log_executor" => "single_thread_executor",
            "log_level" => "debug",
            "appenders" => [{
              "stream" => {
                "file_name" => "log/development.log",
                "formatter" => "color",
              },
            }],
          },
          "production"  => {
            "log_executor" => "single_thread_executor",
            "log_level" => "warn",
            "appenders" => [{
              "stream" => {
                "file_name" => "log/production.log",
                "formatter" => "json",
              },
            }],
          },
          "test"        => {
            "log_executor" => "immediate_executor",
            "log_level" => "warn",
            "appenders" => [{
              "stream" => {
                "file_name" => "log/test.log",
                "formatter" => "color",
              },
            }],
          })
        end
      end

      it_behaves_like "loading default configuration"

      context "when Rack::Directory is undefined" do
        before { hide_const("Rack::Directory") }
        it_behaves_like "loading default configuration"
      end
    end

    context "when sapience.yml file defined in the application" do
      shared_examples "loading application configuration" do
        before do
          create_file("config/sapience.yml",
            ["development:",
             "  log_level: debug",
             "  appenders:",
             "    - stream:",
             "        io: STDOUT",
             "        formatter: json"])
        end

        it "uses the default configuration" do
          expect(load_from_file).to eq(
            "default" => {
              "log_executor" => "single_thread_executor",
              "log_level" => "info",
              "appenders" => [
                {
                  "stream" => {
                    "io" => "STDOUT",
                    "formatter" => "color",
                  },
                },
              ],
            },
            "development" => {
              "log_executor" => "single_thread_executor",
              "log_level" => "debug",
              "appenders" => [
                {
                  "stream" => {
                    "io" => "STDOUT",
                    "formatter" => "json",
                  },
                },
              ],
            },
            "production" => {
              "log_executor" => "single_thread_executor",
              "log_level" => "warn",
              "appenders" => [
                {
                  "stream" => {
                    "file_name" => "log/production.log",
                    "formatter" => "json",
                  },
                },
              ],
            },
            "test" => {
              "log_executor" => "immediate_executor",
              "log_level" => "warn",
              "appenders" => [
                {
                  "stream" => {
                    "file_name" => "log/test.log",
                    "formatter" => "color",
                  },
                },
              ],
            },
          )
        end
        after { delete_file("config/sapience.yml") }
      end

      it_behaves_like "loading application configuration"

      context "when Rack::Directory is undefined" do
        before { hide_const("Rack::Directory") }
        it_behaves_like "loading application configuration"
      end
    end
  end

  describe ".merge_configs" do
    let(:left_config) do
      {
        "default" => {
          "key" => "val",
          "key2" => "val2",
        },
        "development" => {
          "key" => "val",
          "key2" => "val",
        },
      }
    end
    let(:right_config) do
      {
        "development" => {
          "key" => "val",
          "key2" => "val2",
          "key3" => "val3",
        },
        "rspec" => {
          "key" => "val",
          "key2" => "val2",
        },
      }
    end

    subject(:merge_configs) { described_class.merge_configs(left_config, right_config) }
    specify do
      expect(merge_configs).to match(
        "default" => {
          "key" => "val",
          "key2" => "val2",
        },
        "development" => {
          "key" => "val",
          "key2" => "val2",
          "key3" => "val3",
        },
        "rspec" => {
          "key" => "val",
          "key2" => "val2",
        },
      )
    end
  end
end
