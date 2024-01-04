from datetime import datetime, timedelta
from textwrap import dedent
from airflow import DAG

from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator
from airflow.operators.python import BranchPythonOperator
from airflow.utils.trigger_rule import TriggerRule

default_args = {
    'owner': 'kcw',
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

dag_args = dict(
        dag_id = 'test_branch',
        default_args = default_args,
        description = 'tutorial branch DAG',
        schedule_interval = timedelta(hours=1),
        start_date = datetime(2021,1,1),
        tags = ['test_branch']
        )

    
def random_branch():
    from random import randint
    
    return "path1" if randint(1,2) == 1 else "path2"

with DAG(**dag_args) as dag:
    t1 = BashOperator(
        task_id = 'print_date',
        bash_command="date"
        )
    
    t2 = BranchPythonOperator(
        task_id = 'branch',
        python_callable=random_branch
    )
    t3 = BashOperator(
        task_id = "my_name_ko",
        depends_on_past = False,
        bash_command= 'echo "안녕하세요."')
    
    t4 = BashOperator(
        task_id = 'my_name_en',
        depends_on_past = False,
        bash_command='echo "Hi"',
    )

    complete = BashOperator(
        task_id = 'complete',
        depends_on_past = False,
        bash_command= 'echo "complete!"',
        trigger_rule = TriggerRule.NONE_FAILED
    )
    
    dummy_1 = DummyOperator(task_id='path1')
    
    t1 >> t2 >> dummy_1 >> t3 >> complete
    t1 >> t2 >> t4 >> complete