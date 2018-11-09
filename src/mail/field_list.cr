module Mail
  # Field List class provides an enhanced array that keeps a list of
  # email fields in order.  And allows you to insert new fields without
  # having to worry about the order they will appear in.
  class FieldList
    @fields = [] of Field

    def has_field?(field_name)
      @fields.any? { |f| f.responsible_for? field_name }
    end

    def select_fields(field_name)
      @fields.select { |f| f.responsible_for? field_name }
    end

    def get_field(field_name)
      fields = select_fields(field_name)

      case fields.size
      when 0
        nil
      when 1
        fields.first
      else
        fields
      end
    end

    def add_field(field)
      if field.singular?
        replace_field field
      else
        insert_field field
      end
    end

    def push(field)
      add_field(field)
    end

    def <<(field)
      push(field)
    end

    def replace_field(field)
      if first_offset = @fields.index { |f| f.responsible_for? field.name }
        delete_field field.name
        @fields.insert first_offset, field
      else
        insert_field field
      end
    end

    # Insert the field in sorted order.
    #
    # Heavily based on bisect.insort from Python, which is:
    #   Copyright (C) 2001-2013 Python Software Foundation.
    #   Licensed under <http://docs.python.org/license.html>
    #   From <http://hg.python.org/cpython/file/2.7/Lib/bisect.py>
    def insert_field(field)
      lo, hi = 0, @fields.size
      while lo < hi
        mid = (lo + hi).tdiv(2)
        if field < @fields[mid]
          hi = mid
        else
          lo = mid + 1
        end
      end

      @fields.insert lo, field
    end

    def delete_field(name)
      @fields.reject { |f| f.responsible_for? name }
    end

    def summary
      @fields.map { |f| "<#{f.name}: #{f.value}>" }.join(", ")
    end
  end
end
