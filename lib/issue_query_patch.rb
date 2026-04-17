module IssueQueryPatch
  def sort_clause
    original_sort_clause = super
    return original_sort_clause unless pinned_issues_enabled?

    pinned_table = PinnedIssue.table_name

    # 1. ピン留めされているものを最優先 (0: ピン留め, 1: 通常)
    order_pinned = Arel.sql("CASE WHEN #{pinned_table}.id IS NOT NULL THEN 0 ELSE 1 END")

    # 2. ピン留めの中で、無期限(NULL)を一番上(0)、期限ありを下(1)にする
    order_has_expiration = Arel.sql("CASE WHEN #{pinned_table}.expires_at IS NULL THEN 0 ELSE 1 END")

    # 3. 期限ありの中で、期間が長い順（降順: 1週間 -> 1日 -> 1時間）
    # ※もし「1時間 -> 1日 -> 1週間」の順にしたい場合は DESC を ASC に変更してください
    order_expires_at = Arel.sql("#{pinned_table}.expires_at DESC")

    # この3つの条件を配列にまとめる
    pinned_orders = [order_pinned, order_has_expiration, order_expires_at]

    if original_sort_clause.blank?
      pinned_orders
    elsif original_sort_clause.is_a?(Array)
      pinned_orders + original_sort_clause
    else
      pinned_orders + [original_sort_clause]
    end
  end

  def joins_for_order_statement(order_options)
    join_str = super(order_options)
    if pinned_issues_enabled?
      pinned_table = PinnedIssue.table_name
      issue_table = Issue.table_name

      # ActiveRecord::Base.connection.quote を使うことで、
      # 使用中のDB(PG/MySQL/SQLite)に合わせた安全な日時文字列に変換する
      quoted_time = ActiveRecord::Base.connection.quote(Time.current)
      # $1や?を使わずに、エスケープ済みの値を直接埋め込むことで衝突を防ぐ
      pinned_join = "LEFT OUTER JOIN #{pinned_table} ON #{pinned_table}.issue_id = #{issue_table}.id AND (#{pinned_table}.expires_at IS NULL OR #{pinned_table}.expires_at > #{quoted_time})"
      if join_str.present?
        join_str = "#{join_str} #{pinned_join}"
      else
        join_str = pinned_join
      end
    end
    join_str
  end

  private

  def pinned_issues_enabled?
    return false if project.nil?
    project.module_enabled?(:pinned_issues_module)
  end
end

IssueQuery.prepend(IssueQueryPatch) unless IssueQuery.ancestors.include?(IssueQueryPatch)