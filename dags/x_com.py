from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup

from random import randint
from datetime import datetime, timedelta


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


    
def _get_number():
    res = randint(1,10)
    print(f"number is {res}")
    return res
    
def _choose_num():
    print("choose num")

with DAG(
        dag_id="test_xcom",
        default_args=default_args,
        schedule_interval=datetime(minute=30),
        catchup=False) as dag:
    
    dag_start = BashOperator(
            task_id = 'start',
            bash_command= 'echo "start" '
        )
    
    with TaskGroup('choosing_numbers') as choosing_number:
        number_a = PythonOperator(
                task_id = 'choosing_num_a',
                python_callable=_get_number
            )
        
        number_b = PythonOperator(
                task_id = 'choosing_num_b',
                python_callable=_get_number
            )
        
        number_c = PythonOperator(
                task_id = 'choosing_num_c',
                python_callable=_get_number
            )
    choose_number = PythonOperator(
        task_id = "task_4",
        python_callable=_choose_num
    )
    
    dag_start >> choosing_number >> choose_number