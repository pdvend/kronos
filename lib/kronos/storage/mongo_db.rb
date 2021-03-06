# frozen_string_literal: true

require 'kronos/storage/mongo/model/scheduled_task_model'
require 'kronos/storage/mongo/model/report_model'
require 'kronos/storage/mongo/model/lock_model'

module Kronos
  module Storage
    # :reek:UtilityFunction:
    # :reek:TooManyMethods:
    class MongoDb
      SHEDULED_TASK_MODEL = Mongo::Model::ScheduledTaskModel
      REPORT_MODEL = Mongo::Model::ReportModel
      LOCK_MODEL = Mongo::Model::LockModel

      def scheduled_tasks
        # Returns all current Kronos::ScheduledTask, resolved or pending
        SHEDULED_TASK_MODEL.all
      end

      def schedule(scheduled_task)
        # Removes any Kronos::ScheduledTask with same task ID and saves the one in parameter
        remove(scheduled_task.task_id)
        SHEDULED_TASK_MODEL.create(scheduled_task_params(scheduled_task))
      end

      def resolved_tasks
        # Returns a list of task ids that where resolved (where scheduled_task.next_run <= Time.now)
        SHEDULED_TASK_MODEL.where(:next_run.lte => Time.now).pluck(:task_id)
      end

      def remove(task_id)
        # Removes scheduled tasks with task_id
        SHEDULED_TASK_MODEL.where(task_id: task_id).destroy_all
      end

      def reports
        # Returns all previous Kronos::Report that were saved using #register_report
        REPORT_MODEL.all.map(&method(:mount_report))
      end

      def register_report(report)
        # Removes any Kronos::Report with same task ID and saves the one in parameter
        remove_reports_for(report.task_id)
        REPORT_MODEL.create(report_params(report))
      end

      def remove_reports_for(task_id)
        # Removes reports with task_id
        REPORT_MODEL.where(task_id: task_id).destroy_all
      end

      def pending?(task)
        # Checks if task has any pending scheduled task (where scheduled_task.next_run > Time.now)
        query = SHEDULED_TASK_MODEL.where(task_id: task.id)
        query.exists? && query.first.next_run > Time.now
      end

      def locked_task?(task_id)
        LOCK_MODEL.where(task_id: task_id).exists?
      end

      def lock_task(task_id)
        SecureRandom.uuid.tap do |lock_id|
          LOCK_MODEL.create(task_id: task_id, value: lock_id)
        end
      end

      def check_lock(task_id, lock_id)
        LOCK_MODEL.where(task_id: task_id, value: lock_id).exists?
      end

      def release_lock(task_id)
        LOCK_MODEL.where(task_id: task_id).destroy_all
      end

      private

      def mount_report(report_model)
        case report_model.status
        when Kronos::Report::STATUSES[:success]
          mount_success_report(report_model)
        when Kronos::Report::STATUSES[:failure]
          mount_failure_report(report_model)
        end
      end

      def mount_success_report(report_model)
        Kronos::Report.success_from(report_model.task_id, report_model.metadata, report_model.timestamp)
      end

      def mount_failure_report(report_model)
        Kronos::Report.failure_from(report_model.task_id, report_model.exception, report_model.timestamp)
      end

      def scheduled_task_params(scheduled_task)
        {
          task_id: scheduled_task.task_id,
          next_run: scheduled_task.next_run
        }
      end

      def report_params(report)
        {
          task_id: report.task_id,
          status: report.status,
          metadata: report.metadata,
          exception: report.exception,
          timestamp: report.timestamp
        }
      end
    end
  end
end
