# frozen_string_literal: true

require 'spec_helper'

class Section < SitePrism::Section; end
class Page < SitePrism::Page; end

describe SitePrism::Page do
  describe '.section' do
    context 'second argument is a Class' do
      class PageWithSection < SitePrism::Page
        section :section, Section, '.section'
      end

      subject(:page_with_section) { PageWithSection.new }

      it { is_expected.to respond_to(:section) }
    end

    context 'second argument is not a Class and a block given' do
      class PageWithAnonymousSection < SitePrism::Page
        section :anonymous_section, '.section' do |s|
          s.element :title, 'h1'
        end
      end

      subject(:page_with_anonymous_section) { PageWithAnonymousSection.new }

      it { is_expected.to respond_to(:anonymous_section) }
    end

    context 'second argument is not a Class and no block given' do
      subject(:invalid_page) { Page.section(:incorrect_section, '.section') }
      let(:error_message) do
        'You should provide descendant of SitePrism::Section class or/and a block as the second argument.'
      end

      it 'raises an ArgumentError' do
        expect { invalid_page }
          .to raise_error(ArgumentError)
          .with_message(error_message)
      end
    end

    context 'default search arguments' do
      class PageWithSectionWithDefaultSearchArguments < SitePrism::Page
        class SectionWithDefaultArguments < SitePrism::Section
          set_default_search_arguments :css, '.section'
        end

        section  :section_using_defaults, SectionWithDefaultArguments
        section  :section_with_locator,   SectionWithDefaultArguments, '.other-section'
        sections :sections,               SectionWithDefaultArguments
      end
      let(:page) { PageWithSectionWithDefaultSearchArguments.new }

      context 'if default search arguments are not set' do
        let(:search_arguments) { ['.other-section'] }

        it 'should use arguments provided' do
          expect(page).to receive(:find_first).with(*search_arguments).and_return(:element)
          page.section_with_locator
        end
      end

      context 'if default search arguments are set' do
        let(:search_arguments) { [:css, '.section'] }

        it 'should use arguments provided' do
          expect(page).to receive(:find_first).with(*search_arguments).and_return(:element)
          page.section_using_defaults
        end
      end

      context 'if default search arguments are not set and no search arguments provided' do
        it 'should raise ArgumentError' do
          expect do
            class ErroredPage < SitePrism::Page
              section :section, Section
            end
          end.to raise_error(ArgumentError)
        end
      end

      context 'if using sections' do
        let(:search_arguments) { [:css, '.section'] }

        it 'should use arguments provided' do
          expect(page).to receive(:find_all).with(*search_arguments).and_return([:element] * 3)
          expect(SitePrism::Section).to receive(:new).at_least(3).times.with(page, :element)
          page.sections
        end
      end
    end
  end
end

describe SitePrism::Section do
  let(:instance) { SitePrism::Section.new(Page.new, locator) }
  let(:locator) { instance_double('Capybara::Node::Element') }
  let(:section_with_block) { SitePrism::Section.new(Page.new, locator) { 1 + 1 } }

  describe '#default_search_arguments' do
    class BaseSection < SitePrism::Section
      set_default_search_arguments :css, '.default'
    end

    class ChildSection < BaseSection
      set_default_search_arguments :xpath, '//html'
    end

    class SecondChildSection < BaseSection; end

    it 'should be nil by default' do
      expect(Section.default_search_arguments).to be_nil
    end

    it { expect(Section).to respond_to(:set_default_search_arguments) }

    it 'should return default search arguments' do
      expect(BaseSection.default_search_arguments).to eql([:css, '.default'])
    end

    it 'should return only this section default if they are set' do
      expect(ChildSection.default_search_arguments).to eql([:xpath, '//html'])
    end

    it 'should parent section default arguments if defaults are not set' do
      expect(SecondChildSection.default_search_arguments).to eql([:css, '.default'])
    end
  end

  describe 'Object' do
    subject { SitePrism::Section }

    it { is_expected.to respond_to(:element) }
    it { is_expected.to respond_to(:elements) }
    it { is_expected.to respond_to(:section) }
    it { is_expected.to respond_to(:sections) }
  end

  describe '#new' do
    context 'with a block' do
      it 'passes the block to Capybara.within' do
        expect(Capybara).to receive(:within).with(locator)

        section_with_block
      end
    end

    context 'without a block' do
      it 'does not pass a block to Capybara.within' do
        expect(Capybara).not_to receive(:within)

        instance
      end
    end
  end

  describe '#visible?' do
    it 'delegates through root_element' do
      expect(locator).to receive(:visible?)

      instance.visible?
    end
  end

  describe '#text' do
    it 'delegates through root_element' do
      expect(locator).to receive(:text)

      instance.text
    end
  end

  describe '#native' do
    it 'delegates through root_element' do
      expect(locator).to receive(:native)

      instance.native
    end
  end

  describe '#execute_script' do
    it 'delegates through Capybara' do
      expect(Capybara.current_session).to receive(:execute_script).with('JUMP!')

      instance.execute_script('JUMP!')
    end
  end

  describe '#evaluate_script' do
    it 'delegates through Capybara' do
      expect(Capybara.current_session).to receive(:evaluate_script).with('How High?')

      instance.evaluate_script('How High?')
    end
  end

  describe '#parent_page' do
    let(:section) { SitePrism::Section.new(page, '.locator') }
    let(:deeply_nested_section) do
      SitePrism::Section.new(
        SitePrism::Section.new(
          SitePrism::Section.new(
            page, '.locator-section-large'
          ), '.locator-section-medium'
        ), '.locator-small'
      )
    end
    let(:page) { Page.new }

    it 'returns the parent of a section' do
      expect(section.parent_page.class).to eq(Page)

      expect(section.parent_page).to be_a SitePrism::Page
    end

    it 'returns the parent page of a deeply nested section' do
      expect(deeply_nested_section.parent_page.class).to eq(Page)

      expect(deeply_nested_section.parent_page).to be_a SitePrism::Page
    end

    it 'responds to #visible? method' do
      expect(section).to respond_to(:visible?)
    end

    it 'responds to Capybara methods' do
      expect(section).to respond_to(*Capybara::Session::DSL_METHODS)
    end
  end

  describe 'page' do
    subject(:section) { SitePrism::Section.new('parent', root_element).page }

    let(:root_element) { 'root' }

    it { is_expected.to eq('root') }

    context 'when root element is nil' do
      let(:root_element) { nil }

      before { allow(Capybara).to receive(:current_session).and_return('current session') }

      it { is_expected.to eq('current session') }
    end
  end
end
