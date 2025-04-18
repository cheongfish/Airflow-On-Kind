from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id="uv_virtualenv_bash_dag",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
) as dag:

    run_uv_script = BashOperator(
        task_id="run_script_with_uv",
        bash_command="""
        source dags/pyvenv311/bin/activate  # uv로 만든 venv
        """,
    )
    check_packages = BashOperator(
        task_id="check_packages_with_uv",
        bash_command="""
        echo ${pip freeze}
        """,
    )
    run_uv_script >> check_packages
