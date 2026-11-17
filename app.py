import streamlit as st
import pandas as pd
import mysql.connector
from pymongo import MongoClient
from datetime import date, timedelta

# ============================================================
# BANKLEDGER | Premium dark banking analytics dashboard
# Uses the existing MySQL and MongoDB databases.
# ============================================================

st.set_page_config(
    page_title="BankLedger | Banking Intelligence",
    page_icon="🏦",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ----------------------------- THEME -----------------------------

st.markdown(
    """
    <style>
    @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@400;500;600;700;800&display=swap');

    :root {
        --bg: #08111f;
        --panel: #101d30;
        --panel-2: #14243a;
        --line: #233852;
        --muted: #91a4bd;
        --text: #edf4ff;
        --blue: #4c9aff;
        --cyan: #42d4e8;
        --green: #35c995;
        --amber: #f5b84b;
        --red: #ff6b7a;
    }

    html, body, [class*="css"] {
        font-family: 'DM Sans', sans-serif;
    }
    .stApp {
        background:
          radial-gradient(ellipse at 85% 0%, rgba(40,104,174,.16), transparent 32%),
          linear-gradient(135deg, #08111f 0%, #0a1424 55%, #0b1729 100%);
        color: var(--text);
    }
    [data-testid="stHeader"] { background: rgba(8,17,31,.75); }
    [data-testid="stSidebar"] {
        background: linear-gradient(180deg, #0d1a2c 0%, #0a1525 100%);
        border-right: 1px solid #1d3048;
    }
    [data-testid="stSidebar"] > div { padding-top: 1.4rem; }
    [data-testid="stSidebar"] [data-testid="stMarkdownContainer"] p {
        color: #a9bad0;
    }
    h1, h2, h3, h4 {
        font-family: 'Manrope', sans-serif !important;
        color: #f2f7ff !important;
        letter-spacing: -.025em;
    }
    h1 { font-size: 2.05rem !important; font-weight: 800 !important; }
    h2 { font-size: 1.35rem !important; font-weight: 700 !important; }
    h3 { font-size: 1.05rem !important; font-weight: 700 !important; }
    p, label, span { color: inherit; }
    .block-container { padding-top: 2.0rem; padding-bottom: 3rem; max-width: 1500px; }

    div[data-testid="stMetric"] {
        background: linear-gradient(145deg, #14243a, #101d30);
        border: 1px solid #263d59;
        border-radius: 16px;
        padding: 17px 19px;
        box-shadow: 0 8px 26px rgba(0,0,0,.14);
        min-height: 112px;
    }
    div[data-testid="stMetricLabel"] {
        color: #9eb2cb !important;
        font-size: .82rem !important;
        font-weight: 600 !important;
    }
    div[data-testid="stMetricValue"] {
        color: #f4f8ff !important;
        font-family: 'Manrope', sans-serif !important;
        font-weight: 800 !important;
        font-size: 1.65rem !important;
    }
    div[data-testid="stMetricDelta"] { font-size: .75rem !important; }

    .brand {
        display:flex; align-items:center; gap:11px;
        padding: 4px 4px 18px 4px;
    }
    .brand-mark {
        width:42px; height:42px; border-radius:13px;
        display:flex; align-items:center; justify-content:center;
        color:white; font-size:22px;
        background: linear-gradient(135deg,#2877d8,#32c4d8);
        box-shadow: 0 7px 22px rgba(45,139,224,.25);
    }
    .brand-name { color:#f3f7ff; font:800 17px 'Manrope',sans-serif; letter-spacing:.08em; }
    .brand-sub { color:#8298b3; font-size:10px; letter-spacing:.13em; text-transform:uppercase; margin-top:2px; }
    .eyebrow {
        color:#64b4ff; text-transform:uppercase; letter-spacing:.16em;
        font-size:.69rem; font-weight:700; margin-bottom:7px;
    }
    .page-subtitle { color:#91a4bd; font-size:.94rem; margin-top:-8px; margin-bottom:22px; }
    .section-heading {
        display:flex; align-items:center; justify-content:space-between;
        margin: 22px 0 12px 0;
    }
    .section-heading span { color:#91a4bd; font-size:.78rem; }
    .panel {
        background: linear-gradient(145deg, rgba(20,36,58,.96), rgba(14,27,45,.96));
        border:1px solid #243a55; border-radius:16px;
        padding:18px 20px; box-shadow:0 10px 28px rgba(0,0,0,.12);
    }
    .hero {
        background:
          radial-gradient(circle at 85% 20%, rgba(60,158,255,.22), transparent 30%),
          linear-gradient(115deg,#142a45,#102039 65%,#102a40);
        border:1px solid #2b4c70; border-radius:19px;
        padding:23px 26px; margin-bottom:20px;
    }
    .hero-kicker { color:#76c4ff; font-size:.72rem; text-transform:uppercase; letter-spacing:.16em; font-weight:700; }
    .hero-title { color:#f3f8ff; font:800 1.55rem 'Manrope',sans-serif; margin:7px 0 4px 0; }
    .hero-copy { color:#a9bdd5; font-size:.9rem; max-width:700px; }
    .status-pill {
        display:inline-flex; align-items:center; gap:7px;
        border:1px solid #285a55; background:rgba(38,177,132,.10);
        color:#72e0b8; padding:6px 10px; border-radius:30px;
        font-size:.72rem; font-weight:700;
    }
    .status-dot { width:7px; height:7px; border-radius:50%; background:#35c995; display:inline-block; }
    .note {
        background:rgba(245,184,75,.08); border:1px solid rgba(245,184,75,.28);
        border-radius:12px; padding:12px 15px; color:#e9c987; font-size:.84rem;
    }
    .small-muted { color:#8ea2bb; font-size:.78rem; }
    .stButton > button, .stDownloadButton > button {
        border-radius:10px; border:1px solid #3479c4;
        background:linear-gradient(135deg,#236dc1,#248da9);
        color:white; font-weight:700; padding:.55rem 1rem;
    }
    .stButton > button:hover, .stDownloadButton > button:hover {
        border-color:#69b8ff; color:white; background:linear-gradient(135deg,#2b7ed8,#27a1bb);
    }
    div[data-baseweb="select"] > div, div[data-baseweb="input"] > div,
    div[data-baseweb="textarea"] > div {
        background:#101f33; border-color:#2a405c; border-radius:10px;
    }
    [data-testid="stDataFrame"] {
        border:1px solid #243a55; border-radius:12px; overflow:hidden;
    }
    hr { border-color:#233852 !important; }
    footer { visibility:hidden; }
    </style>
    """,
    unsafe_allow_html=True,
)

# ----------------------------- DATABASE HELPERS -----------------------------

def get_mysql_connection():
    cfg = st.secrets["mysql"]
    return mysql.connector.connect(
        host=cfg.get("host", "localhost"),
        user=cfg["user"],
        password=cfg["password"],
        database=cfg.get("database", "BankLedger"),
        connection_timeout=8,
    )


def read_sql(query, params=None):
    connection = get_mysql_connection()
    cursor = None
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(query, params or ())
        return pd.DataFrame(cursor.fetchall())
    finally:
        if cursor is not None:
            cursor.close()
        connection.close()


@st.cache_resource(show_spinner=False)
def get_mongo_client(uri):
    client = MongoClient(uri, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    return client


def get_mongo_database():
    cfg = st.secrets["mongodb"]
    client = get_mongo_client(cfg["uri"])
    return client[cfg.get("database", "BankLedger")]


def money(value):
    try:
        return f"₹{float(value):,.2f}"
    except (TypeError, ValueError):
        return "₹0.00"


def page_header(kicker, title, subtitle):
    st.markdown(f'<div class="eyebrow">{kicker}</div>', unsafe_allow_html=True)
    st.title(title)
    st.markdown(f'<div class="page-subtitle">{subtitle}</div>', unsafe_allow_html=True)


def section(title, detail=""):
    st.markdown(
        f'<div class="section-heading"><h3 style="margin:0">{title}</h3><span>{detail}</span></div>',
        unsafe_allow_html=True,
    )


# ----------------------------- SIDEBAR -----------------------------

with st.sidebar:
    st.markdown(
        """
        <div class="brand">
          <div class="brand-mark">⌂</div>
          <div>
            <div class="brand-name">BANKLEDGER</div>
            <div class="brand-sub">Banking intelligence</div>
          </div>
        </div>
        """,
        unsafe_allow_html=True,
    )
    st.markdown("---")
    page = st.radio(
        "WORKSPACE",
        [
            "◈  Overview",
            "⇄  Transactions",
            "⚑  Risk monitoring",
            "▥  Analytics",
            "⌘  Database health",
        ],
        label_visibility="visible",
    )
    st.markdown("---")
    st.markdown(
        '<div class="small-muted">PROJECT ENVIRONMENT</div>'
        '<div style="color:#d9e7f7;font-weight:700;margin-top:6px">DEVELOPMENT</div>'
        '<div class="small-muted" style="margin-top:4px">MySQL · MongoDB Atlas · Python</div>',
        unsafe_allow_html=True,
    )
    st.markdown("<br>", unsafe_allow_html=True)
    st.caption("BankLedger • Educational project")

# ----------------------------- CONNECTION STATUS -----------------------------

try:
    test_connection = get_mysql_connection()
    test_connection.close()
    mysql_ok = True
except Exception as exc:
    st.error("MySQL connection failed. Check the [mysql] section in .streamlit/secrets.toml.")
    st.code(str(exc))
    st.stop()

# ----------------------------- OVERVIEW -----------------------------

if page == "◈  Overview":
    page_header(
        "BANKING OPERATIONS / OVERVIEW",
        "Banking overview",
        "A live snapshot of customers, accounts, transaction activity and monitoring alerts.",
    )

    st.markdown(
        """
        <div class="hero">
          <div class="hero-kicker">BankLedger intelligence centre</div>
          <div class="hero-title">Your banking activity, at a glance.</div>
          <div class="hero-copy">Monitor transaction flows, review high-value activity and explore operational patterns across your sample banking database.</div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    try:
        customers = int(read_sql("SELECT COUNT(*) AS n FROM customers")["n"].iloc[0])
        accounts = int(read_sql("SELECT COUNT(*) AS n FROM accounts")["n"].iloc[0])
        transactions = int(read_sql("SELECT COUNT(*) AS n FROM transactions")["n"].iloc[0])
        deposits = read_sql("""
            SELECT COALESCE(SUM(amount),0) AS total
            FROM transactions WHERE transaction_type='DEPOSIT'
        """)["total"].iloc[0]
        withdrawals = read_sql("""
            SELECT COALESCE(SUM(amount),0) AS total
            FROM transactions WHERE transaction_type='WITHDRAWAL'
        """)["total"].iloc[0]
        alerts = int(read_sql("SELECT COUNT(*) AS n FROM transaction_flags")["n"].iloc[0])

        k1, k2, k3 = st.columns(3)
        k1.metric("TOTAL CUSTOMERS", f"{customers:,}")
        k2.metric("ACTIVE ACCOUNTS IN DATA", f"{accounts:,}")
        k3.metric("TRANSACTIONS PROCESSED", f"{transactions:,}")
        k4, k5, k6 = st.columns(3)
        k4.metric("TOTAL DEPOSITS", money(deposits))
        k5.metric("TOTAL WITHDRAWALS", money(withdrawals))
        k6.metric("MONITORING ALERTS", f"{alerts:,}")

        section("Transaction flow", "Breakdown by transaction type")
        distribution = read_sql("""
            SELECT transaction_type,
                   COUNT(*) AS transaction_count,
                   COALESCE(SUM(amount),0) AS total_amount
            FROM transactions
            GROUP BY transaction_type
            ORDER BY transaction_count DESC
        """)
        chart_left, chart_right = st.columns(2)
        with chart_left:
            st.markdown('<div class="panel">', unsafe_allow_html=True)
            st.markdown("**Transaction volume**")
            if not distribution.empty:
                st.bar_chart(
                    distribution.set_index("transaction_type")["transaction_count"],
                    use_container_width=True,
                )
            st.markdown("</div>", unsafe_allow_html=True)
        with chart_right:
            st.markdown('<div class="panel">', unsafe_allow_html=True)
            st.markdown("**Transaction value**")
            if not distribution.empty:
                st.bar_chart(
                    distribution.set_index("transaction_type")["total_amount"],
                    use_container_width=True,
                )
            st.markdown("</div>", unsafe_allow_html=True)

        section("Latest transactions", "Most recent 8 records")
        latest = read_sql("""
            SELECT transaction_id, account_id, transaction_type,
                   amount, transaction_date, description
            FROM transactions
            ORDER BY transaction_date DESC
            LIMIT 8
        """)
        st.dataframe(latest, use_container_width=True, hide_index=True)

        st.markdown(
            '<div class="note">Risk note: project alerts are simulated high-value deposit alerts (above the configured ₹80,000 threshold). They are not confirmed fraud findings.</div>',
            unsafe_allow_html=True,
        )
    except Exception as exc:
        st.error("Unable to load overview data.")
        st.exception(exc)

# ----------------------------- TRANSACTIONS -----------------------------

elif page == "⇄  Transactions":
    page_header(
        "BANKING OPERATIONS / LEDGER",
        "Transaction explorer",
        "Search the transaction ledger and narrow results using account, transaction type and date filters.",
    )

    f1, f2, f3 = st.columns([1, 1, 1])
    with f1:
        account_id = st.text_input("Account ID", placeholder="All accounts")
    with f2:
        txn_type = st.selectbox(
            "Transaction type",
            ["ALL", "DEPOSIT", "WITHDRAWAL", "TRANSFER_IN", "TRANSFER_OUT"],
        )
    with f3:
        max_rows = st.selectbox("Maximum records", [100, 250, 500, 1000], index=2)

    d1, d2 = st.columns(2)
    with d1:
        start_date = st.date_input("From date", value=date.today() - timedelta(days=365))
    with d2:
        end_date = st.date_input("To date", value=date.today())

    if start_date > end_date:
        st.warning("The start date must be on or before the end date.")
    elif account_id.strip() and not account_id.strip().isdigit():
        st.warning("Enter a numeric Account ID.")
    else:
        query = """
            SELECT transaction_id, account_id, transaction_type, amount,
                   transaction_date, description, reference_no
            FROM transactions
            WHERE DATE(transaction_date) BETWEEN %s AND %s
        """
        params = [start_date, end_date]
        if account_id.strip():
            query += " AND account_id = %s"
            params.append(int(account_id))
        if txn_type != "ALL":
            query += " AND transaction_type = %s"
            params.append(txn_type)
        query += " ORDER BY transaction_date DESC LIMIT %s"
        params.append(int(max_rows))

        try:
            result = read_sql(query, tuple(params))
            total_value = result["amount"].sum() if not result.empty else 0
            m1, m2 = st.columns(2)
            m1.metric("RECORDS DISPLAYED", f"{len(result):,}")
            m2.metric("VALUE OF DISPLAYED RECORDS", money(total_value))
            st.dataframe(result, use_container_width=True, hide_index=True)
            if not result.empty:
                st.download_button(
                    "Download filtered transactions (CSV)",
                    result.to_csv(index=False).encode("utf-8"),
                    file_name="bankledger_filtered_transactions.csv",
                    mime="text/csv",
                )
        except Exception as exc:
            st.error("Unable to retrieve transactions.")
            st.exception(exc)

# ----------------------------- RISK MONITORING -----------------------------

elif page == "⚑  Risk monitoring":
    page_header(
        "RISK & COMPLIANCE / ALERT QUEUE",
        "Suspicious activity monitoring",
        "Review transactions that matched the project's simulated high-value deposit alert rule.",
    )
    st.markdown(
        '<div class="note">Important: an alert is a review signal only. It does not prove suspicious intent or financial crime.</div>',
        unsafe_allow_html=True,
    )
    try:
        flags = read_sql("""
            SELECT f.flag_id, f.transaction_id, t.account_id,
                   t.transaction_type, t.amount, t.transaction_date,
                   f.flag_type, f.severity, f.flag_reason,
                   f.status, f.flagged_at
            FROM transaction_flags f
            JOIN transactions t ON f.transaction_id = t.transaction_id
            ORDER BY f.flagged_at DESC
        """)
        high = int((flags["severity"] == "HIGH").sum()) if not flags.empty else 0
        open_alerts = int((flags["status"] == "OPEN").sum()) if not flags.empty else 0
        total_value = flags["amount"].sum() if not flags.empty else 0

        a, b, c = st.columns(3)
        a.metric("TOTAL ALERTS", f"{len(flags):,}")
        b.metric("HIGH SEVERITY", f"{high:,}")
        c.metric("VALUE UNDER REVIEW", money(total_value))

        severity = st.selectbox("Severity filter", ["ALL", "HIGH", "MEDIUM", "LOW"])
        status = st.selectbox("Alert status", ["ALL"] + sorted(flags["status"].dropna().unique().tolist()) if not flags.empty else ["ALL"])
        filtered = flags.copy()
        if severity != "ALL":
            filtered = filtered[filtered["severity"] == severity]
        if status != "ALL":
            filtered = filtered[filtered["status"] == status]

        st.markdown(f"**{len(filtered):,} alert records**")
        st.dataframe(filtered, use_container_width=True, hide_index=True)
        if not filtered.empty:
            st.download_button(
                "Download alert report (CSV)",
                filtered.to_csv(index=False).encode("utf-8"),
                file_name="bankledger_alerts.csv",
                mime="text/csv",
            )
    except Exception as exc:
        st.error("Unable to load the alert queue.")
        st.exception(exc)

# ----------------------------- ANALYTICS -----------------------------

elif page == "▥  Analytics":
    page_header(
        "INSIGHTS / PERFORMANCE",
        "Transaction analytics",
        "Explore daily transaction trends, hourly activity and branch-level deposit performance.",
    )
    try:
        daily = read_sql("""
            SELECT DATE(transaction_date) AS transaction_day,
                   COUNT(*) AS transaction_count,
                   COALESCE(SUM(amount),0) AS total_amount
            FROM transactions
            GROUP BY DATE(transaction_date)
            ORDER BY transaction_day
        """)
        hourly = read_sql("""
            SELECT HOUR(transaction_date) AS transaction_hour,
                   COUNT(*) AS transaction_count
            FROM transactions
            GROUP BY HOUR(transaction_date)
            ORDER BY transaction_hour
        """)
        types = read_sql("""
            SELECT transaction_type, COUNT(*) AS transaction_count,
                   COALESCE(SUM(amount),0) AS total_amount
            FROM transactions GROUP BY transaction_type
            ORDER BY transaction_count DESC
        """)

        if not daily.empty:
            daily["transaction_day"] = pd.to_datetime(daily["transaction_day"])
            section("Daily transaction volume", "Transactions per day")
            st.line_chart(
                daily.set_index("transaction_day")["transaction_count"],
                use_container_width=True,
            )
            section("Daily transaction value", "Total amount per day")
            st.area_chart(
                daily.set_index("transaction_day")["total_amount"],
                use_container_width=True,
            )

        left, right = st.columns(2)
        with left:
            section("Hourly activity", "0–23 hours")
            if not hourly.empty:
                st.bar_chart(
                    hourly.set_index("transaction_hour")["transaction_count"],
                    use_container_width=True,
                )
        with right:
            section("Transaction type mix", "Count by type")
            if not types.empty:
                st.bar_chart(
                    types.set_index("transaction_type")["transaction_count"],
                    use_container_width=True,
                )

        section("Branch deposit performance", "Deposit count and total amount")
        try:
            branch_data = read_sql("""
                SELECT b.branch_name,
                       COUNT(t.transaction_id) AS deposit_count,
                       COALESCE(SUM(t.amount),0) AS deposit_amount
                FROM branches b
                JOIN accounts a ON b.branch_id = a.branch_id
                JOIN transactions t ON a.account_id = t.account_id
                WHERE t.transaction_type = 'DEPOSIT'
                GROUP BY b.branch_id, b.branch_name
                ORDER BY deposit_amount DESC
            """)
            st.dataframe(branch_data, use_container_width=True, hide_index=True)
            if not branch_data.empty:
                st.bar_chart(
                    branch_data.set_index("branch_name")["deposit_amount"],
                    use_container_width=True,
                )
        except Exception:
            st.info("Branch chart unavailable: check the branch table's column names.")

        with st.expander("View daily analytics data"):
            st.dataframe(daily, use_container_width=True, hide_index=True)
    except Exception as exc:
        st.error("Unable to calculate analytics.")
        st.exception(exc)

# ----------------------------- DATABASE HEALTH -----------------------------

elif page == "⌘  Database health":
    page_header(
        "PLATFORM / CONNECTIVITY",
        "Database health",
        "Inspect the record counts in your existing MySQL database and MongoDB Atlas collections.",
    )
    st.markdown("### MySQL · BankLedger")
    st.markdown('<span class="status-pill"><span class="status-dot"></span> MYSQL CONNECTED</span>', unsafe_allow_html=True)

    tables = [
        "customers", "branches", "account_types", "accounts",
        "transactions", "loans", "transaction_flags", "balance_audit",
    ]
    try:
        rows = []
        for table in tables:
            count_df = read_sql(f"SELECT COUNT(*) AS total FROM `{table}`")
            rows.append({"Table": table, "Records": int(count_df["total"].iloc[0])})
        mysql_df = pd.DataFrame(rows)
        total_mysql = int(mysql_df["Records"].sum())
        st.metric("TOTAL MYSQL RECORDS", f"{total_mysql:,}")
        st.dataframe(mysql_df, use_container_width=True, hide_index=True)
    except Exception as exc:
        st.error("Could not read MySQL table counts.")
        st.exception(exc)

    st.markdown("---")
    st.markdown("### MongoDB Atlas")
    try:
        mongo_db = get_mongo_database()
        mongo_db.command("ping")
        mongo_collections = ["transactions", "transaction_flags", "crud_demo"]
        mongo_rows = []
        for collection in mongo_collections:
            mongo_rows.append({
                "Collection": collection,
                "Documents": int(mongo_db[collection].count_documents({})),
            })
        mongo_df = pd.DataFrame(mongo_rows)
        st.markdown('<span class="status-pill"><span class="status-dot"></span> MONGODB ATLAS CONNECTED</span>', unsafe_allow_html=True)
        st.metric("TOTAL MONGODB DOCUMENTS", f"{int(mongo_df['Documents'].sum()):,}")
        st.dataframe(mongo_df, use_container_width=True, hide_index=True)
    except Exception as exc:
        st.warning("MongoDB Atlas is not reachable. Check the [mongodb] URI in secrets.toml and your Atlas Network Access settings.")
        st.caption(str(exc))

# ----------------------------- FOOTER -----------------------------

st.markdown("---")
st.markdown(
    '<div style="text-align:center;color:#7187a2;font-size:.72rem;letter-spacing:.08em">'
    'BANKLEDGER  •  BANKING TRANSACTIONS & ACTIVITY MONITORING  •  EDUCATIONAL DATASET'
    '</div>',
    unsafe_allow_html=True,
)
