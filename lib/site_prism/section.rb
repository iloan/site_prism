# frozen_string_literal: true

require 'site_prism/loadable'

module SitePrism
  class Section
    include Capybara::DSL
    include ElementChecker
    include Loadable
    extend ElementContainer

    attr_reader :root_element, :parent

    def self.set_default_search_arguments(*args)
      @default_search_arguments = args
    end

    def self.default_search_arguments
      @default_search_arguments ||
        (
          superclass.respond_to?(:default_search_arguments) &&
          superclass.default_search_arguments
        ) ||
        nil
    end

    def initialize(parent, root_element)
      @parent = parent
      @root_element = root_element
      Capybara.within(@root_element) { yield(self) } if block_given?
    end

    # Capybara::DSL module "delegates" Capybara methods to the "page" method
    def page
      root_element || Capybara.current_session
    end

    def visible?
      page.visible?
    end

    def execute_script(input)
      Capybara.current_session.execute_script(input)
    end

    def evaluate_script(input)
      Capybara.current_session.evaluate_script(input)
    end

    def parent_page
      candidate_page = parent
      until candidate_page.is_a?(SitePrism::Page)
        candidate_page = candidate_page.parent
      end
      candidate_page
    end

    def native
      root_element.native
    end

    private

    def find_first(*find_args)
      root_element.find(*find_args)
    end

    def element_exists?(*find_args)
      root_element.has_selector?(*find_args) unless root_element.nil?
    end

    def element_does_not_exist?(*find_args)
      root_element.has_no_selector?(*find_args) unless root_element.nil?
    end
  end
end
