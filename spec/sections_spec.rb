# frozen_string_literal: true

require 'spec_helper'

describe SitePrism::Page do
  subject { Page.new }

  class SingleSection < SitePrism::Section
    element :single_section_element, '.foo'
  end
  class PluralSections < SitePrism::Section; end

  class Page < SitePrism::Page
    section  :single_section,  SingleSection, '.bob'
    sections :plural_sections, PluralSections, '.tim'

    section :section_with_a_block, SingleSection, '.bob' do
      element :block_element, '.btn'
    end
  end

  describe '.section' do
    it 'should be callable' do
      expect(SitePrism::Page).to respond_to(:section)
    end

    it { is_expected.to respond_to(:single_section) }
    it { is_expected.to respond_to(:has_single_section?) }
  end

  describe '.section with class and block' do
    before do
      expect(subject).to receive(:find_first).and_return(:element)
    end

    it 'should be an instance of provided section class' do
      expect(subject.section_with_a_block.class.ancestors).to include(SingleSection)
    end

    it 'should have elements from the base section' do
      expect(subject.section_with_a_block).to respond_to(:single_section_element)
    end

    it 'should have elements from the block' do
      expect(subject.section_with_a_block).to respond_to(:block_element)
    end
  end

  describe '.sections' do
    it 'should be callable' do
      expect(SitePrism::Page).to respond_to(:sections)
    end

    it { is_expected.to respond_to(:plural_sections) }
    it { is_expected.to respond_to(:has_plural_sections?) }
  end
end
