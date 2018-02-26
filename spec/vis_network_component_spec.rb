require 'spec_helper'

describe 'Hyperloop::Vis::Component', js: true do

  it 'creates a component by using the mixin and renders it' do
    mount 'OuterComponent' do
      class VisComponent
        include Hyperloop::Vis::Network::Mixin

        render_with_dom_node do |dom_node, data|
          net = Vis::Network.new(dom_node, data)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          DIV { VisComponent(vis_data: {nodes: data})}
        end
      end
    end
    expect(page.body).to include('<canvas')
  end

  it 'creates a component by inheriting and renders it' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Network::Component
        render_with_dom_node do |dom_node, data|
          net = Vis::Network.new(dom_node, data)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          DIV { VisComponent(vis_data: {nodes: data})}
        end
      end
    end
    expect(page.body).to include('<canvas')
  end

  it 'actually passes the params to the component' do
    mount 'OuterComponent' do
      class VisComponent < Hyperloop::Vis::Network::Component
        def self.passed_data
          @@passed_data
        end
        def self.passed_options
          @@passed_options
        end
        render_with_dom_node do |dom_node, data, options|
          @@passed_data = data
          @@passed_options = options
          net = Vis::Network.new(dom_node, data)
        end
      end
      class OuterComponent < Hyperloop::Component
        render do
          data = Vis::DataSet.new([{id: 1, name: 'foo'}, {id: 2, name: 'bar'}, {id: 3, name: 'pub'}])
          DIV { VisComponent(vis_data: {nodes: data}, options: {autoresize: true})}
        end
      end
    end
    expect(page.body).to include('<canvas')
    expect_evaluate_ruby('VisComponent.passed_data.has_key?(:nodes)').to eq(true)
    expect_evaluate_ruby('VisComponent.passed_options.has_key?(:autoresize)').to eq(true)
  end
end
