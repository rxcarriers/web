module InvoicesHelper
    
    def prettify_nil(value)
        if value.nil?
            'n/a'
        elsif value.length > 30
            value[0..27] + '...'
        else
            value
        end
    end
    
    def render_class
        if params[:period] == 'week'
            Invoice.where(pharmacy_id: current_pharmacy.id).group_by_week(:created_at, format: "%a").count
        elsif params[:period] == 'month'
            Invoice.where(pharmacy_id: current_pharmacy.id).group_by_month(:created_at, format: "%b %Y").count
        else
            Invoice.where(pharmacy_id: current_pharmacy.id).group_by_day_of_week(:created_at, format: "%a").count
        end
    end
    
    def next_payment_attempt
        begin
            Invoice.where(pharmacy_id: current_pharmacy.id).last.billing_date
        rescue
         'n/a'
        end
    end
    
    def url
        request.original_url
    end
    
    def invoices_sum
        @all_invoices = Invoice.where(pharmacy_id: current_pharmacy.id).today
        @all_invoices.reduce(0) {|sum, invoice| sum += invoice.amount}.to_s
    end
    
    def timestamp(object)
        [object.updated_at.strftime("%B %-dth %Y"), "at", object.updated_at.strftime("%I:%M %p")].join(" ")
    end
    
    def to_dollar(item)
        item.to_s.prepend("$") 
    end
    
    def status(invoice)
        if invoice.status.nil?
            return 'failed'
        end
        begin
            case invoice.status
                when 'succeeded'
                    'succeeded'
                else
                    'failed'
            end
        rescue
            'failed'
        end
    end
    
    def failed(array)
        inv = array.select{|a| a.stripe_status == 'failed'}
        return inv
    end
    def succeeded(array)
        inv = array.select{|a| a.stripe_status == 'succeeded'}
        return inv
    end
    def pending(array)
        inv = array.select{|a| a.stripe_status == 'pending'}
        return inv
    end
    
    def recent_invoices
        @pharmacy = current_pharmacy
        @invoices = Invoice.where(id: @pharmacy.id).order('updated_at DESC')
        return @invoices
    end
    
    def old_invoices
        @pharmacy = current_pharmacy
        @invoices = Invoice.where(id: @pharmacy.id).order('updated_at ASC')
        return @invoices
    end
    
    def invoice_sort
        url = request.original_url
        url_end = url[url.index("/payment-history")..-1]
        case url_end
            when "/payment-history?status=pending"
                "pending_payments"
            when "/payment-history?status=succeeded"
                "succeeded_payments"
            when "/payment-history?status=failed"
                "failed_payments"
            when "/payment-history?amount=asc"
                "low_high"
            when "/payment-history?amount=desc"
                "high_low"
            when "/payment-history?date=asc"
                "old_new"
            when "/payment-history?date=desc"
                "new_old"
            else
                "all"
        end
    end
    
end
