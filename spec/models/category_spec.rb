require 'rails_helper'

RSpec.describe Category, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      category = Category.new(name: "Conciertos", slug: "conciertos", active: true)
      expect(category).to be_valid
    end

    it "requires a name" do
      category = Category.new(name: nil, slug: "test")
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("no puede estar en blanco")
    end

    it "requires a unique name" do
      Category.create!(name: "Único", slug: "unico", active: true)
      category = Category.new(name: "Único", slug: "otro")
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("ya está en uso")
    end

    it "requires a slug" do
      category = Category.new(name: "Test", slug: nil)
      expect(category).not_to be_valid
      expect(category.errors[:slug]).to include("no puede estar en blanco")
    end

    it "requires a unique slug" do
      Category.create!(name: "Uno", slug: "slug-unico", active: true)
      category = Category.new(name: "Dos", slug: "slug-unico")
      expect(category).not_to be_valid
      expect(category.errors[:slug]).to include("ya está en uso")
    end
  end

  describe "defaults" do
    it "is active by default" do
      category = Category.new(name: "Default", slug: "default")
      expect(category.active).to be true
    end
  end

  describe "scopes" do
    it ".active returns only active categories" do
      active = Category.create!(name: "Activo", slug: "activo", active: true)
      inactive = Category.create!(name: "Inactivo", slug: "inactivo", active: false)

      expect(Category.active).to include(active)
      expect(Category.active).not_to include(inactive)
    end
  end

  describe "associations" do
    it "has many events with restrict_with_error" do
      category = Category.create!(name: "Dep", slug: "dep", active: true)
      expect(category.events).to be_empty
    end
  end
end
