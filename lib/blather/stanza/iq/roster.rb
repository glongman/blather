module Blather
class Stanza
class Iq

  class Roster < Query
    register :roster, nil, 'jabber:iq:roster'

    ##
    # Any new items are added to the query
    def initialize(type = nil, item = nil)
      super type
      query << item if item
    end

    ##
    # Inherit the XMPPNode to create a proper Roster object.
    # Creates RosterItem objects out of each roster item as well.
    def inherit(node)
      # remove the current set of nodes
      items.each { |i| i.remove! }
      super
      # transmogrify nodes into RosterItems
      items.each { |i| query << RosterItem.new(i); i.remove! }
      self
    end

    ##
    # Roster items
    def items
      items = query.find('//item', self.class.ns)
      items = query.find('//query_ns:item', :query_ns => self.class.ns) if items.empty?
      items.map { |i| RosterItem.new(i) }
    end

    class RosterItem < XMPPNode
      ##
      # [jid] may be either a JID or XMPPNode. 
      # [name] name alias of the given JID
      # [subscription] subscription type
      # [ask] ask subscription sub-state
      def initialize(jid = nil, name = nil, subscription = nil, ask = nil)
        super :item

        if jid.is_a?(XML::Node)
          self.inherit jid
        else
          self.jid = jid
          self.name = name
          self.subscription = subscription
          self.ask = ask
        end
      end

      ##
      # Roster item's JID
      def jid
        (j = attributes[:jid]) ? JID.new(j) : nil
      end
      attribute_writer :jid

      attribute_accessor :name, :to_sym => false

      attribute_accessor :subscription, :ask

      ##
      # The groups roster item belongs to
      def groups
        find(:group).map { |g| g.content }
      end

      ##
      # Set the roster item's groups
      # must be an array
      def groups=(new_groups)
        find(:group).each { |g| g.remove! }
        new_groups.uniq.each { |g| self << XMPPNode.new(:group, g) } if new_groups
      end

      ##
      # Convert the roster item to a proper stanza all wrapped up
      # This facilitates new subscriptions
      def to_stanza
        Roster.new(:set, self)
      end
    end #RosterItem
  end #Roster

end #Iq
end #Stanza
end