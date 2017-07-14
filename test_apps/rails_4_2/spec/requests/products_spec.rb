# frozen_string_literal: true
require "rails_helper"

describe "Products", type: :request do
  describe "GET /products" do
    describe "ActiveSupport::Notification" do
      context "when metrics is configured" do
        before do
          # ActiveRecord::Base.logger = Logger.new(STDOUT)
          Rails.logger.level = :debug
          FactoryGirl.create_list(:product, 10)
          allow_any_instance_of(Sapience::Extensions::ActiveRecord::Notifications)
            .to receive(:record).and_return(true)
        end

        it "records a batch of metrics" do
          expect(Sapience.metrics).to receive(:increment) do |metric_name, options|
            expect(metric_name).to eq("rails.request")
            expect(options[:tags])
              .to match_array(
                %w(method:get status:200 action:index controller:products format:html),
              )
          end
          expect(Sapience.metrics).to receive(:timing) do |metric_name, duration, options|
            expect(metric_name).to eq("rails.request.time")
            expect(duration).to be_a(Float).and be > 0
            expect(options[:tags])
              .to match_array(
                %w(method:get status:200 action:index controller:products format:html),
              )
          end

          expect(Sapience.metrics).to receive(:timing) do |metric_name, duration, options|
            expect(metric_name).to eq("rails.request.time.db")
            expect(duration).to be_a(Float).and be > 0
            expect(options[:tags])
              .to match_array(
                %w(method:get status:200 action:index controller:products format:html),
              )
          end

          expect(Sapience.metrics).to receive(:timing) do |metric_name, duration, options|
            expect(metric_name).to eq("rails.request.time.view")
            expect(duration).to be_a(Float).and be > 0
            expect(options[:tags])
              .to match_array(
                %w(method:get status:200 action:index controller:products format:html),
            )
          end

          get products_path
        end
      end
    end
  end
end
