"""token verification secret and settings

Revision ID: d31fe8912345
Revises: c20ab5490eb8
Create Date: 2026-10-09 23:30:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = 'd31fe8912345'
down_revision: Union[str, None] = 'c20ab5490eb8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add verification columns to tokens
    op.add_column('tokens', sa.Column('verification_secret', sa.String(length=32), nullable=True))
    op.add_column('tokens', sa.Column('verification_verified', sa.Boolean(), server_default=sa.text('false'), nullable=False))
    op.add_column('tokens', sa.Column('verified_counter_id', sa.String(length=64), sa.ForeignKey('counters.id', ondelete='SET NULL'), nullable=True))
    op.add_column('tokens', sa.Column('verified_officer_id', sa.String(length=64), nullable=True))
    op.add_column('tokens', sa.Column('verified_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('tokens', sa.Column('failed_verification_attempts', sa.Integer(), server_default='0', nullable=False))

    # 2. Add max_verification_attempts to office_settings
    op.add_column('office_settings', sa.Column('max_verification_attempts', sa.Integer(), server_default='5', nullable=False))


def downgrade() -> None:
    op.drop_column('office_settings', 'max_verification_attempts')
    op.drop_column('tokens', 'failed_verification_attempts')
    op.drop_column('tokens', 'verified_at')
    op.drop_column('tokens', 'verified_officer_id')
    op.drop_column('tokens', 'verified_counter_id')
    op.drop_column('tokens', 'verification_verified')
    op.drop_column('tokens', 'verification_secret')
