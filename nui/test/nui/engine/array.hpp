#pragma once

#include "value.hpp"

#include <boost/container/stable_vector.hpp>

#include <list>
#include <memory>

namespace Nui::Tests::Engine
{
    class Array
    {
      public:
        Array() = default;
        Array(const Array&) = default;
        Array(Array&&) = default;
        Array& operator=(const Array&) = default;
        Array& operator=(Array&&) = default;

        Value& operator[](std::size_t index)
        {
            return *values_[index];
        }

        const Value& operator[](std::size_t index) const
        {
            return *values_[index];
        }

        std::weak_ptr<Value> reference(std::size_t index)
        {
            return values_[index];
        }

        auto begin() const
        {
            return values_.begin();
        }

        auto end() const
        {
            return values_.end();
        }

        auto size() const
        {
            return values_.size();
        }

        bool empty() const
        {
            return values_.empty();
        }

        std::weak_ptr<Value> push_back(Value const& value)
        {
            values_.emplace_back(std::make_shared<Value>(value));
            return values_.back();
        }

        std::weak_ptr<Value> push_back(std::shared_ptr<Value> const& value)
        {
            values_.push_back(value);
            return values_.back();
        }

      private:
        boost::container::stable_vector<std::shared_ptr<Value>> values_;
    };
}