from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup

default_args = {
    'owner': 'owner-name',
    'depends_on_past': False,
    'email': ['your-email@g.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=15),
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
    # 'wait_for_downstream': False,
    # 'dag': dag,
    # 'sla': timedelta(hours=2),
    # 'execution_timeout': timedelta(seconds=300),
    # 'on_failure_callback': some_function,
    # 'on_success_callback': some_other_function,
    # 'on_retry_callback': another_function,
    # 'sla_miss_callback': yet_another_function,
    # 'trigger_rule': 'all_success'
}
with DAG('parallel_dag',
    default_args=default_args,
    schedule_interval=datetime(minute=30),
    catchup=False) as dag:

    task1 = BashOperator(
        task_id='task_1',
        bash_command='sleep 3'
    )
    
    with TaskGroup(group_id='processing_tasks') as processing_tasks:
        task2 = BashOperator(
            task_id='task_2',
            bash_command='sleep 3'
        )

        task3 = BashOperator(
            task_id='task_3',
            bash_command='sleep 3'
        )

        task4 = BashOperator(
            task_id='task_4',
            bash_command='sleep 3'
        )

        [task2, task3] >> task4 
    
    task5 = BashOperator(
        task_id='task_5',
        bash_command='sleep 3'
    )


    task1 >> processing_tasks >> task5